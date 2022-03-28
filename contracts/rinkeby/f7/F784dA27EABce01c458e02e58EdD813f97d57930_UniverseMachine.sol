// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Common.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@divergencetech/ethier/contracts/sales/ArbitraryPriceSeller.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "../Base64.sol";
import "./Parameters.sol";
import "./IUniverseMachineParameters.sol";
import "./IUniverseMachineRenderer.sol";
import "./IPublicMintable.sol";

contract UniverseMachine is ERC721Common, ArbitraryPriceSeller, IPublicMintable, IERC2981 {

    bytes constant private JSON_URI_PREFIX = "data:application/json;base64,";   

    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC165Checker for address;
    using ERC721Redeemer for ERC721Redeemer.Claims;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;     
    
    /** @notice Contract responsible for rendering images from seeds. */
    IUniverseMachineRenderer public renderer;

    /**
    @notice Flag to disable use of setRenderer().
     */
    bool public rendererLocked = false;

    /**
    @notice Permanently sets the renderer-lock flag to true.
     */
    function lockRenderer() external onlyOwner {
        require(
            address(renderer).supportsInterface(
                type(IUniverseMachineRenderer).interfaceId
            ),
            "Not IUniverseMachineRenderer"
        );
        rendererLocked = true;
    }

    /**
    @notice Sets the address of the rendering contract.
    @dev No checks are performed when setting, but lockRenderer() ensures that
    the final address implements the IUniverseMachineRenderer interface.
     */
    function setRenderer(address _renderer) public onlyOwner {
        require(!rendererLocked, "Renderer locked");
        renderer = IUniverseMachineRenderer(_renderer);
    }

    /** @notice Contract responsible for creating metadata from seeds. */
    IUniverseMachineParameters public parameters;

    /**
    @notice Flag to disable use of setParameters().
     */
    bool public parametersLocked = false;

    /**
    @notice Permanently sets the parameters-lock flag to true.
     */
    function lockParameters() external onlyOwner {
        require(
            address(parameters).supportsInterface(
                type(IUniverseMachineParameters).interfaceId
            ),
            "Not IUniverseMachineParameters"
        );
        parametersLocked = true;
    }

    /**
    @notice Sets the address of the parameters contract.
    @dev No checks are performed when setting, but lockParameters() ensures that
    the final address implements the IUniverseMachineParameters interface.
     */
    function setParameters(address _parameters) public onlyOwner {
        require(!parametersLocked, "Parameters locked");
        parameters = IUniverseMachineParameters(_parameters);
    } 

    /** @notice Flag whether to use IPFS or direct rendering. */
    bool public useCDN = true;

    /**
    @notice Flag to disable use of toggleCDN().
     */
    bool public cdnLocked = false;

    /**
    @notice Permanently sets the CDN-lock flag to true.
     */
    function lockCDN() external onlyOwner {        
        cdnLocked = true;
    }

    /**
    @notice Toggles use of a CDN.
     */
    function toggleCDN() public onlyOwner {
        require(!cdnLocked, "CDN locked");
        useCDN = !useCDN;
    }

    string private _cdnBaseUrl;
    string private _externalUrl;
    string private _description;

    constructor(uint totalInventory)
        ERC721Common("the Universe Machine", "TUM")
        ArbitraryPriceSeller(
            Seller.SellerConfig({
                totalInventory: totalInventory,
                maxPerAddress: 0,
                maxPerTx: 0,
                freeQuota: 0,
                reserveFreeQuota: false,
                lockFreeQuota: true,
                lockTotalInventory: true
            }),
            payable(0xFDc91fE3f9fC29A8c53D2Bbb7dB39A29b2639736)
        ) 
    {  
        _externalUrl = "https://linktr.ee/praystation";
        _description = "the Universe Machine is an algorithm I have been working on since 2014. The program can generate 1 of 55 unique generative patterns. Maps 56,000 textures to a grid based Bezier path segment function... to build a universe in 9 possible color sets.";
        _cdnBaseUrl = "https://kohi.art/api/images/rinkeby/tum";
        setRoyaltyBeneficiary(payable(0xFBC78f494aD61d90F02A3258e527De1321095AcB));
    }

    /**
    @notice Sets external details.
    */
    function setDetails(string memory externalUrl, string memory description, string memory cdnBaseUrl) public onlyOwner {
        _externalUrl = externalUrl;
        _description = description;
        _cdnBaseUrl = cdnBaseUrl;
    } 

    /**
    @notice Minting price for presales.
     */
    uint256 public presalePrice = 0.22 ether;

    /**
    @notice Minting price for public minters.
     */
    uint256 public publicPrice = 0.314159 ether;    

    /**
    @notice Updates the prices for the two tiers.
     */
    function setPrice(uint256 public_, uint256 presale) external onlyOwner {
        publicPrice = public_;
        presalePrice = presale;
    }

    /**
    @notice Proxy contract from which public minting requests are allowed.
     */
    address public _publicMinter;

    /**
    @notice Sets the public-minting contract.
     */
    function setPublicMinter(address publicMinter) external onlyOwner {
        _publicMinter = publicMinter;
    }

    /**
    @notice Mint as a member of the public, but only via minter contract.
    @dev This allows for arbitrary control of minting logic post deployment.
     */
    function mintPublic(address to, uint256 n) external payable {
        require(msg.sender == _publicMinter, "Direct public minting");
        _purchase(to, n, publicPrice);
    }

    /**
    @notice Set of addresses from which valid signatures will be accepted to
    provide access to minting.
     */
    EnumerableSet.AddressSet private signers;

    /**
    @notice Add an address allowed to sign minting access.
     */
    function addSigner(address signer) external onlyOwner {
        signers.add(signer);
    }

    /**
    @notice Remove an address from those allowed to sign minting access.
     */
    function removeSigner(address signer) external onlyOwner {
        signers.remove(signer);
    }

    /**
    @notice Already-redeemed signed-minting messages.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Already-redeemed allow list addresses.
     */
    mapping(address => bool) public usedAddresses;    

    /**
    @notice Mint one token as a holder of a signature; most likely from the allow list.
     */
    function mintWithSignature(bytes calldata signature) external payable {
        require(!usedAddresses[msg.sender], "address already claimed allow list mint");
        signers.requireValidSignature(
            abi.encodePacked(msg.sender, uint16(1)),
            signature,
            usedMessages
        );
        _purchase(msg.sender, 1, presalePrice);
        usedAddresses[msg.sender] = true;
    }

    /**
    @notice Partially fulfills the ERC721Enumerable interface.
     */
    Monotonic.Increaser public totalSupply;

    /**
    @notice The per-token seeds used to generate images.
     */
    mapping(uint256 => int32) public seeds;

    /**
    @notice Override of the Seller purchasing logic to mint the required number
    of tokens. The freeOfCharge boolean flag is deliberately ignored.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        uint256 nextId = totalSupply.current();
        uint256 end = nextId + n;

        // These are close enough to unpredictable / uncontrollable to be
        // sufficiently random for our purpose. Only a miner could really
        // influence this.
        bytes memory entropyBase = abi.encodePacked(
            address(this),
            block.coinbase,
            block.number,
            to
        );

        for (; nextId < end; ++nextId) {
            _safeMint(to, nextId);
            seeds[nextId] = int32(int(uint(keccak256(abi.encodePacked(entropyBase, nextId)))));
        }
        totalSupply.add(n);
    }
     
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(address(parameters) != address(0), "No parameters");
        require(useCDN || address(renderer) != address(0), "No renderer");
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory metadata = getTokenMetadata(tokenId);
        string memory dataUri = string(abi.encodePacked(JSON_URI_PREFIX, Base64.encode(bytes(metadata), bytes(metadata).length)));
        return dataUri;
    }

    function getTokenMetadata(uint tokenId) private view returns (string memory metadata) {
        
        Parameters memory p = parameters.getParameters(tokenId, seeds[tokenId]);

        string memory tokenName = this.name();
        string memory tokenIdString = Strings.toString(tokenId);

        string memory image;
        if(useCDN) {
            image = string(abi.encodePacked(_cdnBaseUrl, '/', tokenIdString));
        } else {
            image = renderer.image(p);
        }        

        metadata = string(abi.encodePacked('{"description":"', _description, 
        '","external_url":"', _externalUrl, 
        '","name":"', tokenName, ' #', tokenIdString, 
        '","image":"', image,
        '",', getTokenMetadataAttributes(p),
        '}'));
    }

    function getTokenMetadataAttributes(Parameters memory p) private view returns (string memory attributes) {

        uint8 numberOfTraits = 0;

        attributes = string(abi.encodePacked('"attributes":['));
        {
            (string memory a, uint8 t) = appendTrait(attributes, "Universe", 
            string(abi.encodePacked(Strings.toString(p.whichMasterSet), " of 55")), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }

        uint8[4] memory universe = parameters.getUniverse(uint8(p.whichMasterSet));

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Map", 
            Strings.toString(uint32(universe[0])), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Texture", 
            Strings.toString(uint32(universe[1])), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Flow", 
            Strings.toString(uint32(universe[2])), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Orbit", 
            Strings.toString(uint32(universe[3])), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Universe Color", 
            Strings.toString(uint32(p.whichColor + 1)), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }        

        attributes = string(abi.encodePacked(attributes, "]"));
    }

    function appendTrait(string memory attributes, string memory trait_type, string memory value, uint8 numberOfTraits) private pure returns (string memory, uint8) {        
        if(bytes(value).length > 0) {
            numberOfTraits++;
            attributes = string(abi.encodePacked(attributes, numberOfTraits > 1 ? ',' : '', '{"trait_type":"', trait_type, '","value":"', value, '"}'));
        }
        return (attributes, numberOfTraits);
    }

    /**
    @notice Defines royalty proportion in hundredths of a percent.
     */
    uint256 public royaltyBasisPoints = 750;
    uint256 private constant BASIS_POINT_DENOMINATOR = 100 * 100;

    /**
    @notice Sets royalty proportion.
    @param basisPoints Measured in hundredths of a percent; 1% = 100; 1.5% = 150; etc.
     */
    function setRoyalties(uint256 basisPoints) external onlyOwner {
        require(basisPoints <= BASIS_POINT_DENOMINATOR, ">100%");
        royaltyBasisPoints = basisPoints;
    }

    address payable private royaltyBeneficiary;

    /// @notice Sets the recipient of secondary revenues.
    function setRoyaltyBeneficiary(address payable _beneficiary) public onlyOwner {
        royaltyBeneficiary = _beneficiary;
    }

    /**
    @notice Implements ERC2981.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        // Probably safe to assume that salePrice will be less than max(uint256)/10000 ;)
        return (
            royaltyBeneficiary == address(0) ? Seller.beneficiary : royaltyBeneficiary, 
            (salePrice * royaltyBasisPoints) / BASIS_POINT_DENOMINATOR
        );
    }

    /**
    @notice Adds ERC2981 interface to the set of already-supported interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Common, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
@title SignatureChecker
@notice Additional functions for EnumerableSet.Addresset that require a valid
ECDSA signature of a standardized message, signed by any member of the set.
 */
library SignatureChecker {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
    @notice Requires that the message has not been used previously and that the
    recovered signer is contained in the signers AddressSet.
    @dev Convenience wrapper for message generation + signature verification
    + marking message as used
    @param signers Set of addresses from which signatures are accepted.
    @param usedMessages Set of already-used messages.
    @param signature ECDSA signature of message.
     */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        bytes memory data,
        bytes calldata signature,
        mapping(bytes32 => bool) storage usedMessages
    ) internal {
        bytes32 message = generateMessage(data);
        require(
            !usedMessages[message],
            "SignatureChecker: Message already used"
        );
        usedMessages[message] = true;
        requireValidSignature(signers, message, signature);
    }

    /**
    @notice Requires that the message has not been used previously and that the
    recovered signer is contained in the signers AddressSet.
    @dev Convenience wrapper for message generation + signature verification.
     */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        bytes memory data,
        bytes calldata signature
    ) internal view {
        bytes32 message = generateMessage(data);
        requireValidSignature(signers, message, signature);
    }

    /**
    @notice Requires that the message has not been used previously and that the
    recovered signer is contained in the signers AddressSet.
    @dev Convenience wrapper for message generation from address +
    signature verification.
     */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        address a,
        bytes calldata signature
    ) internal view {
        bytes32 message = generateMessage(abi.encodePacked(a));
        requireValidSignature(signers, message, signature);
    }

    /**
    @notice Common validator logic, checking if the recovered signer is
    contained in the signers AddressSet.
    */
    function validSignature(
        EnumerableSet.AddressSet storage signers,
        bytes32 message,
        bytes calldata signature
    ) internal view returns (bool) {
        return signers.contains(ECDSA.recover(message, signature));
    }

    /**
    @notice Requires that the recovered signer is contained in the signers
    AddressSet.
    @dev Convenience wrapper that reverts if the signature validation fails.
    */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        bytes32 message,
        bytes calldata signature
    ) internal view {
        require(
            validSignature(signers, message, signature),
            "SignatureChecker: Invalid signature"
        );
    }

    /**
    @notice Generates a message for a given data input that will be signed
    off-chain using ECDSA.
    @dev For multiple data fields, a standard concatenation using 
    `abi.encodePacked` is commonly used to build data.
     */
    function generateMessage(bytes memory data)
        internal
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(data);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721PreApproval.sol";
import "../utils/OwnerPausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

/**
@notice An ERC721 contract with common functionality:
 - OpenSea gas-free listings
 - OpenZeppelin Pausable
 - OpenZeppelin Pausable with functions exposed to Owner only
 */
contract ERC721Common is ERC721Pausable, ERC721PreApproval, OwnerPausable {
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    /// @notice Requires that the token exists.
    modifier tokenExists(uint256 tokenId) {
        require(ERC721._exists(tokenId), "ERC721Common: Token doesn't exist");
        _;
    }

    /// @notice Requires that msg.sender owns or is approved for the token.
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Common: Not approved nor owner"
        );
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Pausable, ERC721PreApproval) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721, ERC721PreApproval)
    {
        ERC721PreApproval.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721, ERC721PreApproval)
        returns (bool)
    {
        return ERC721PreApproval.isApprovedForAll(owner, operator);
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
@notice Allows holders of ERC721 tokens to redeem rights to some claim; for
example, the right to mint a token of some other collection.
*/
library ERC721Redeemer {
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    /**
    @notice Storage value to track already-claimed redemptions for a specific
    token collection.
     */
    struct Claims {
        /**
        @dev This field MUST NOT be considered part of the public API. Instead,
        prefer `using ERC721Redeemer for ERC721Redeemer.Claims` and utilise the
        provided functions.
         */
        mapping(uint256 => uint256) _total;
    }

    /**
    @notice Storage value to track already-claimed redemptions for a specific
    token collection, given that there is only a single claim allowed per
    tokenId.
     */
    struct SingleClaims {
        /**
        @dev This field MUST NOT be considered part of the public API. Instead,
        prefer `using ERC721Redeemer for ERC721Redeemer.SingleClaims` and
        utilise the provided functions.
         */
        BitMaps.BitMap _claimed;
    }

    /**
    @notice Emitted when a token's claim is redeemed.
     */
    event Redemption(
        IERC721 indexed token,
        address indexed redeemer,
        uint256 tokenId,
        uint256 n
    );

    /**
    @notice Checks that the redeemer is allowed to redeem the claims for the
    tokenIds by being either the owner or approved address for all tokenIds, and
    updates the Claims to reflect this.
    @dev For more efficient gas usage, recurring values in tokenIds SHOULD be
    adjacent to one another as this will batch expensive operations. The
    simplest way to achieve this is by sorting tokenIds.
    @param tokenIds The token IDs for which the claims are being redeemed. If
    maxAllowance > 1 then identical tokenIds can be passed more than once; see
    dev comments.
    @return The number of redeemed claims; either 0 or tokenIds.length;
     */
    function redeem(
        Claims storage claims,
        uint256 maxAllowance,
        address redeemer,
        IERC721 token,
        uint256[] calldata tokenIds
    ) internal returns (uint256) {
        if (maxAllowance == 0 || tokenIds.length == 0) {
            return 0;
        }

        // See comment for `endSameId`.
        bool multi = maxAllowance > 1;

        for (
            uint256 i = 0;
            i < tokenIds.length; /* note increment at end */

        ) {
            uint256 tokenId = tokenIds[i];
            requireOwnerOrApproved(token, tokenId, redeemer);

            uint256 n = 1;
            if (multi) {
                // If allowed > 1 we can save on expensive operations like
                // checking ownership / remaining allowance by batching equal
                // tokenIds. The algorithm assumes that equal IDs are adjacent
                // in the array.
                uint256 endSameId;
                for (
                    endSameId = i + 1;
                    endSameId < tokenIds.length &&
                        tokenIds[endSameId] == tokenId;
                    endSameId++
                ) {}
                n = endSameId - i;
            }

            claims._total[tokenId] += n;
            if (claims._total[tokenId] > maxAllowance) {
                revertWithTokenId(
                    "ERC721Redeemer: over allowance for",
                    tokenId
                );
            }
            i += n;

            emit Redemption(token, redeemer, tokenId, n);
        }

        return tokenIds.length;
    }

    /**
    @notice Checks that the redeemer is allowed to redeem the single claim for
    each of the tokenIds by being either the owner or approved address for all
    tokenIds, and updates the SingleClaims to reflect this.
    @param tokenIds The token IDs for which the claims are being redeemed. Only
    a single claim can be made against a tokenId.
    @return The number of redeemed claims; either 0 or tokenIds.length;
     */
    function redeem(
        SingleClaims storage claims,
        address redeemer,
        IERC721 token,
        uint256[] calldata tokenIds
    ) internal returns (uint256) {
        if (tokenIds.length == 0) {
            return 0;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            requireOwnerOrApproved(token, tokenId, redeemer);

            if (claims._claimed.get(tokenId)) {
                revertWithTokenId(
                    "ERC721Redeemer: over allowance for",
                    tokenId
                );
            }

            claims._claimed.set(tokenId);
            emit Redemption(token, redeemer, tokenId, 1);
        }
        return tokenIds.length;
    }

    /**
    @dev Reverts if neither the owner nor approved for the tokenId.
     */
    function requireOwnerOrApproved(
        IERC721 token,
        uint256 tokenId,
        address redeemer
    ) private view {
        if (
            token.ownerOf(tokenId) != redeemer &&
            token.getApproved(tokenId) != redeemer
        ) {
            revertWithTokenId(
                "ERC721Redeemer: not approved nor owner of",
                tokenId
            );
        }
    }

    /**
    @notice Reverts with the concatenation of revertMsg and tokenId.toString().
    @dev Used to save gas by constructing the revert message only as required,
    instead of passing it to require().
     */
    function revertWithTokenId(string memory revertMsg, uint256 tokenId)
        private
        pure
    {
        revert(string(abi.encodePacked(revertMsg, " ", tokenId.toString())));
    }

    /**
    @notice Returns the number of claimed redemptions for the token.
     */
    function claimed(Claims storage claims, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return claims._total[tokenId];
    }

    /**
    @notice Returns whether the token has had a claim made against it.
     */
    function claimed(SingleClaims storage claims, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return claims._claimed.get(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "./Seller.sol";

/**
@dev The Seller base contract has a convenience function _purchase(to,n) that
calls the standard function as _purchase(to,n,0). This would result in a free
purchase, to the convenience variant is overriden and always reverts with this
error.
 */
error ImplicitFreePurchase();

/**
@notice A Seller with an arbitrary price passed in externally.
 */
abstract contract ArbitraryPriceSeller is Seller {
    constructor(
        Seller.SellerConfig memory sellerConfig,
        address payable _beneficiary
    ) Seller(sellerConfig, _beneficiary) {}

    /**
    @notice Block accidental usage of the convenience function that would
    default to a free sale.
     */
    function _purchase(address, uint256) internal pure override {
        revert ImplicitFreePurchase();
    }

    /**
    @notice Override of Seller.cost() with price passed via metadata.
    @return n*costEach;
     */
    function cost(uint256 n, uint256 costEach)
        public
        pure
        override
        returns (uint256)
    {
        return n * costEach;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

/**
@notice Provides monotonic increasing and decreasing values, similar to
OpenZeppelin's Counter but (a) limited in direction, and (b) allowing for steps
> 1.
 */
library Monotonic {
    /**
    @notice Holds a value that can only increase.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and add().
     */
    struct Increaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Increaser.
    function current(Increaser storage incr) internal view returns (uint256) {
        return incr.value;
    }

    /// @notice Adds x to the Increaser's value.
    function add(Increaser storage incr, uint256 x) internal {
        incr.value += x;
    }

    /**
    @notice Holds a value that can only decrease.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and subtract().
     */
    struct Decreaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Decreaser.
    function current(Decreaser storage decr) internal view returns (uint256) {
        return decr.value;
    }

    /// @notice Subtracts x from the Decreaser's value.
    function subtract(Decreaser storage decr, uint256 x) internal {
        decr.value -= x;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data, uint length) internal pure returns (string memory) {
        if (data.length == 0 || length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Kohi/_Structs.sol";
import "./Bezier.sol";
import "./Star.sol";

struct Parameters {

    uint32 whichMasterSet;
    int32 whichColor;
    int32 endIdx;
    int32 cLen;

    uint8[] myColorsR;
    uint8[] myColorsG;
    uint8[] myColorsB;

    int32[] whichTex;
    int32[] whichColorFlow;
    int32[] whichRot;
    int32[] whichRotDir;       
    
    Vector2[] gridPoints;

    Bezier[] paths;
    uint32 numPaths;

    Star[] starPositions;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "./Parameters.sol";

interface IUniverseMachineParameters is IERC165 {

    function getUniverse(uint8 index) external view returns (uint8[4] memory universe);

    function getParameters(uint256 tokenId, int32 seed)
        external
        view
        returns (Parameters memory parameters);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./Parameters.sol";
import "../Kohi/Graphics2D.sol";

interface IUniverseMachineRenderer is IERC165 {    
    function image(Parameters memory parameters) external view returns (string memory);
    function render(uint256 tokenId, int32 seed, address parameters) external view returns (uint8[] memory);    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPublicMintable {
    function mintPublic(address to, uint256 n) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "../thirdparty/opensea/OpenSeaGasFreeListing.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @notice Pre-approval of OpenSea proxies for gas-less listing
/// @dev This wrapper allows users to revoke the pre-approval of their
/// associated proxy and emits the corresponding events. This is necessary for
/// external tools to index approvals correctly and inform the user.
/// @dev The pre-approval is triggered on a per-wallet basis during the first
/// transfer transactions. It will only be enabled for wallets with an existing
/// proxy. Not having a proxy incurs a gas overhead.
/// @dev This wrapper optimizes for the following scenario:
/// - The majority of users already have a wyvern proxy
/// - Most of them want to transfer tokens via wyvern exchanges
abstract contract ERC721PreApproval is ERC721 {
    /// @dev It is important that Active remains at first position, since this
    /// is the scenario that we are trying to optimize for.
    enum State {
        Active,
        Inactive
    }

    /// @notice The state of the pre-approval for a given owner
    mapping(address => State) private state;

    /// @dev Returns true if either standard `isApprovedForAll()` or if the
    /// `operator` is the OpenSea proxy for the `owner` provided the
    /// pre-approval is active.
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (super.isApprovedForAll(owner, operator)) {
            return true;
        }

        return
            state[owner] == State.Active &&
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator);
    }

    /// @dev Uses the standard `setApprovalForAll` or toggles the pre-approval
    /// state if `operator` is the OpenSea proxy for the sender.
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        address owner = _msgSender();
        if (operator == OpenSeaGasFreeListing.proxyFor(owner)) {
            state[owner] = approved ? State.Active : State.Inactive;
            emit ApprovalForAll(owner, operator, approved);
        } else {
            super._setApprovalForAll(owner, operator, approved);
        }
    }

    /// @dev Checks if the receiver has an existing proxy. If not, the
    /// pre-approval is disabled.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // Exclude burns and inactive pre-approvals
        if (to == address(0) || state[to] == State.Inactive) {
            return;
        }

        address operator = OpenSeaGasFreeListing.proxyFor(to);

        // Disable if `to` has no proxy
        if (operator == address(0)) {
            state[to] = State.Inactive;
            return;
        }

        // Avoid emitting unnecessary events.
        if (balanceOf(to) == 0) {
            emit ApprovalForAll(to, operator, true);
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice A Pausable contract that can only be toggled by the Owner.
contract OwnerPausable is Ownable, Pausable {
    /// @notice Pauses the contract.
    function pause() public onlyOwner {
        Pausable._pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        Pausable._unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

// Inspired by BaseOpenSea by Simon Fremaux (@dievardump) but without the need
// to pass specific addresses depending on deployment network.
// https://gist.github.com/dievardump/483eb43bc6ed30b14f01e01842e3339b/

import "./ProxyRegistry.sol";

/// @notice Library to achieve gas-free listings on OpenSea.
library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        address proxy = proxyFor(owner);
        return proxy != address(0) && proxy == operator;
    }

    /**
    @notice Returns the OpenSea proxy address for the owner.
     */
    function proxyFor(address owner) internal view returns (address) {
        address registry;
        uint256 chainId;

        assembly {
            chainId := chainid()
            switch chainId
            // Production networks are placed higher to minimise the number of
            // checks performed and therefore reduce gas. By the same rationale,
            // mainnet comes before Polygon as it's more expensive.
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 137 {
                // polygon
                registry := 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
            case 80001 {
                // mumbai
                registry := 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
            }
            case 1337 {
                // The geth SimulatedBackend iff used with the ethier
                // openseatest package. This is mocked as a Wyvern proxy as it's
                // more complex than the 0x ones.
                registry := 0xE1a2bbc877b29ADBC56D2659DBcb0ae14ee62071
            }
        }

        // Unlike Wyvern, the registry itself is the proxy for all owners on 0x
        // chains.
        if (registry == address(0) || chainId == 137 || chainId == 80001) {
            return registry;
        }

        return address(ProxyRegistry(registry).proxies(owner));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overriden in child contracts.
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

/// @notice A minimal interface describing OpenSea's Wyvern proxy registry.
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
@dev This pattern of using an empty contract is cargo-culted directly from
OpenSea's example code. TODO: it's likely that the above mapping can be changed
to address => address without affecting anything, but further investigation is
needed (i.e. is there a subtle reason that OpenSea released it like this?).
 */
contract OwnableDelegateProxy {

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "../utils/Monotonic.sol";
import "../utils/OwnerPausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
@notice An abstract contract providing the _purchase() function to:
 - Enforce per-wallet / per-transaction limits
 - Calculate required cost, forwarding to a beneficiary, and refunding extra
 */
abstract contract Seller is OwnerPausable, ReentrancyGuard {
    using Address for address payable;
    using Monotonic for Monotonic.Increaser;
    using Strings for uint256;

    /**
    @dev Note that the address limits are vulnerable to wallet farming.
    @param maxPerAddress Unlimited if zero.
    @param maxPerTex Unlimited if zero.
    @param freeQuota Maximum number that can be purchased free of charge by
    the contract owner.
    @param reserveFreeQuota Whether to excplitly reserve the freeQuota amount
    and not let it be eroded by regular purchases.
    @param lockFreeQuota If true, calls to setSellerConfig() will ignore changes
    to freeQuota. Can be locked after initial setting, but not unlocked. This
    allows a contract owner to commit to a maximum number of reserved items.
    @param lockTotalInventory Similar to lockFreeQuota but applied to
    totalInventory.
    */
    struct SellerConfig {
        uint256 totalInventory;
        uint256 maxPerAddress;
        uint256 maxPerTx;
        uint248 freeQuota;
        bool reserveFreeQuota;
        bool lockFreeQuota;
        bool lockTotalInventory;
    }

    constructor(SellerConfig memory config, address payable _beneficiary) {
        setSellerConfig(config);
        setBeneficiary(_beneficiary);
    }

    /// @notice Configuration of purchase limits.
    SellerConfig public sellerConfig;

    /// @notice Sets the seller config.
    function setSellerConfig(SellerConfig memory config) public onlyOwner {
        require(
            config.totalInventory >= config.freeQuota,
            "Seller: excessive free quota"
        );
        require(
            config.totalInventory >= _totalSold.current(),
            "Seller: inventory < already sold"
        );
        require(
            config.freeQuota >= purchasedFreeOfCharge.current(),
            "Seller: free quota < already used"
        );

        // Overriding the in-memory fields before copying the whole struct, as
        // against writing individual fields, gives a greater guarantee of
        // correctness as the code is simpler to read.
        if (sellerConfig.lockTotalInventory) {
            config.lockTotalInventory = true;
            config.totalInventory = sellerConfig.totalInventory;
        }
        if (sellerConfig.lockFreeQuota) {
            config.lockFreeQuota = true;
            config.freeQuota = sellerConfig.freeQuota;
        }
        sellerConfig = config;
    }

    /// @notice Recipient of revenues.
    address payable public beneficiary;

    /// @notice Sets the recipient of revenues.
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    /**
    @dev Must return the current cost of a batch of items. This may be constant
    or, for example, decreasing for a Dutch auction or increasing for a bonding
    curve.
    @param n The number of items being purchased.
    @param metadata Arbitrary data, propagated by the call to _purchase() that
    can be used to charge different prices. This value is a uint256 instead of
    bytes as this allows simple passing of a set cost (see
    ArbitraryPriceSeller).
     */
    function cost(uint256 n, uint256 metadata)
        public
        view
        virtual
        returns (uint256);

    /**
    @dev Called by both _purchase() and purchaseFreeOfCharge() after all limits
    have been put in place; must perform all contract-specific sale logic, e.g.
    ERC721 minting. When _handlePurchase() is called, the value returned by
    Seller.totalSold() will be the pre-purchase amount.
    @param to The recipient of the item(s).
    @param n The number of items allowed to be purchased, which MAY be less than
    to the number passed to _purchase() but SHALL be greater than zero.
    @param freeOfCharge Indicates that the call originated from
    purchaseFreeOfCharge() and not _purchase().
    */
    function _handlePurchase(
        address to,
        uint256 n,
        bool freeOfCharge
    ) internal virtual;

    /**
    @notice Tracks total number of items sold by this contract, including those
    purchased free of charge by the contract owner.
     */
    Monotonic.Increaser private _totalSold;

    /// @notice Returns the total number of items sold by this contract.
    function totalSold() public view returns (uint256) {
        return _totalSold.current();
    }

    /**
    @notice Tracks the number of items already bought by an address, regardless
    of transferring out (in the case of ERC721).
    @dev This isn't public as it may be skewed due to differences in msg.sender
    and tx.origin, which it treats in the same way such that
    sum(_bought)>=totalSold().
     */
    mapping(address => uint256) private _bought;

    /**
    @notice Returns min(n, max(extra items addr can purchase)) and reverts if 0.
    @param zeroMsg The message with which to revert on 0 extra.
     */
    function _capExtra(
        uint256 n,
        address addr,
        string memory zeroMsg
    ) internal view returns (uint256) {
        uint256 extra = sellerConfig.maxPerAddress - _bought[addr];
        if (extra == 0) {
            revert(string(abi.encodePacked("Seller: ", zeroMsg)));
        }
        return Math.min(n, extra);
    }

    /// @notice Emitted when a buyer is refunded.
    event Refund(address indexed buyer, uint256 amount);

    /// @notice Emitted on all purchases of non-zero amount.
    event Revenue(
        address indexed beneficiary,
        uint256 numPurchased,
        uint256 amount
    );

    /// @notice Tracks number of items purchased free of charge.
    Monotonic.Increaser private purchasedFreeOfCharge;

    /**
    @notice Allows the contract owner to purchase without payment, within the
    quota enforced by the SellerConfig.
     */
    function purchaseFreeOfCharge(address to, uint256 n)
        public
        onlyOwner
        whenNotPaused
    {
        uint256 freeQuota = sellerConfig.freeQuota;
        n = Math.min(n, freeQuota - purchasedFreeOfCharge.current());
        require(n > 0, "Seller: Free quota exceeded");

        uint256 totalInventory = sellerConfig.totalInventory;
        n = Math.min(n, totalInventory - _totalSold.current());
        require(n > 0, "Seller: Sold out");

        _handlePurchase(to, n, true);

        _totalSold.add(n);
        purchasedFreeOfCharge.add(n);
        assert(_totalSold.current() <= totalInventory);
        assert(purchasedFreeOfCharge.current() <= freeQuota);
    }

    /**
    @notice Convenience function for calling _purchase() with empty costMetadata
    when unneeded.
     */
    function _purchase(address to, uint256 requested) internal virtual {
        _purchase(to, requested, 0);
    }

    /**
    @notice Enforces all purchase limits (counts and costs) before calling
    _handlePurchase(), after which the received funds are disbursed to the
    beneficiary, less any required refunds.
    @param to The final recipient of the item(s).
    @param requested The number of items requested for purchase, which MAY be
    reduced when passed to _handlePurchase().
    @param costMetadata Arbitrary data, propagated in the call to cost(), to be
    optionally used in determining the price.
     */
    function _purchase(
        address to,
        uint256 requested,
        uint256 costMetadata
    ) internal nonReentrant whenNotPaused {
        /**
         * ##### CHECKS
         */
        SellerConfig memory config = sellerConfig;

        uint256 n = config.maxPerTx == 0
            ? requested
            : Math.min(requested, config.maxPerTx);

        uint256 maxAvailable;
        uint256 sold;

        if (config.reserveFreeQuota) {
            maxAvailable = config.totalInventory - config.freeQuota;
            sold = _totalSold.current() - purchasedFreeOfCharge.current();
        } else {
            maxAvailable = config.totalInventory;
            sold = _totalSold.current();
        }

        n = Math.min(n, maxAvailable - sold);
        require(n > 0, "Seller: Sold out");

        if (config.maxPerAddress > 0) {
            bool alsoLimitSender = _msgSender() != to;
            bool alsoLimitOrigin = tx.origin != _msgSender() && tx.origin != to;

            n = _capExtra(n, to, "Buyer limit");
            if (alsoLimitSender) {
                n = _capExtra(n, _msgSender(), "Sender limit");
            }
            if (alsoLimitOrigin) {
                n = _capExtra(n, tx.origin, "Origin limit");
            }

            _bought[to] += n;
            if (alsoLimitSender) {
                _bought[_msgSender()] += n;
            }
            if (alsoLimitOrigin) {
                _bought[tx.origin] += n;
            }
        }

        uint256 _cost = cost(n, costMetadata);
        if (msg.value < _cost) {
            revert(
                string(
                    abi.encodePacked(
                        "Seller: Costs ",
                        (_cost / 1e9).toString(),
                        " GWei"
                    )
                )
            );
        }

        /**
         * ##### EFFECTS
         */

        _handlePurchase(to, n, false);
        _totalSold.add(n);
        assert(_totalSold.current() <= config.totalInventory);

        /**
         * ##### INTERACTIONS
         */

        // Ideally we'd be using a PullPayment here, but the user experience is
        // poor when there's a variable cost or the number of items purchased
        // has been capped. We've addressed reentrancy with both a nonReentrant
        // modifier and the checks, effects, interactions pattern.

        if (_cost > 0) {
            beneficiary.sendValue(_cost);
            emit Revenue(beneficiary, n, _cost);
        }

        if (msg.value > _cost) {
            address payable reimburse = payable(_msgSender());
            uint256 refund = msg.value - _cost;

            // Using Address.sendValue() here would mask the revertMsg upon
            // reentrancy, but we want to expose it to allow for more precise
            // testing. This otherwise uses the exact same pattern as
            // Address.sendValue().
            (bool success, bytes memory returnData) = reimburse.call{
                value: refund
            }("");
            // Although `returnData` will have a spurious prefix, all we really
            // care about is that it contains the ReentrancyGuard reversion
            // message so we can check in the tests.
            require(success, string(returnData));

            emit Refund(reimburse, refund);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./_Enums.sol";

struct SortedY {
    int32 start;
    int32 count;
}

struct Vector2 {
    int64 x;
    int64 y;
}

struct ScanlineSpan {
    int32 x;
    int32 length;
    int32 coverIndex;
}

struct Rectangle {
    int64 left;
    int64 bottom;
    int64 right;
    int64 top;
}

struct VertexData {
    Command command;
    Vector2 position;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Kohi/_Structs.sol";
import "../Kohi/Fix64V1.sol";
import "../Kohi/Trig256.sol";

struct Bezier
{
    Vector2 a;
    Vector2 b;
    Vector2 c;
    Vector2 d;
    int32 len;
    int64[] arcLengths;
}

library BezierMethods {

    function create(Vector2 memory t, Vector2 memory h, Vector2 memory s, Vector2 memory i) internal pure returns (Bezier memory result) {
        result.a = t;
        result.b = h;
        result.c = s;
        result.d = i;
        result.len = 100;
        result.arcLengths = new int64[](uint32(result.len + 1));
        result.arcLengths[0] = 0;

        int64 n = xFunc(result, 0);
        int64 r = yFunc(result, 0);
        int64 e = 0;

        for (int32 ax = 1; ax <= result.len; ax += 1)
        {
            int64 z = Fix64V1.mul(42949672 /* 0.01 */, ax * Fix64V1.ONE);
            int64 c = xFunc(result, z);
            int64 u = yFunc(result, z);

            int64 y = Fix64V1.sub(n, c);
            int64 o = Fix64V1.sub(r, u);

            int64 t0 = Fix64V1.mul(y, y);
            int64 t1 = Fix64V1.mul(o, o);

            int64 sqrt = Fix64V1.add(t0, t1);
            e = Fix64V1.add(e, Trig256.sqrt(sqrt));
            result.arcLengths[uint32(ax)] = e;
            n = c;
            r = u;
        }
    }

    function xFunc(Bezier memory self, int64 t) internal pure returns (int64) {
        int64 t0 = Fix64V1.sub(Fix64V1.ONE, t);
        int64 t1 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(t0, self.a.x)));
        int64 t2 = Fix64V1.mul(Fix64V1.mul(Fix64V1.mul(Fix64V1.mul(t0, t0), 3 * Fix64V1.ONE), t), self.b.x);
        int64 t3 = Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t0, Fix64V1.mul(Fix64V1.mul(t, t), self.c.x)));
        int64 t4 = Fix64V1.mul(t, Fix64V1.mul(t, Fix64V1.mul(t, self.d.x)));

        return Fix64V1.add(Fix64V1.add(t1, t2), Fix64V1.add(t3, t4));
    }

    function yFunc(Bezier memory self, int64 t) internal pure returns (int64) {
        int64 t0 = Fix64V1.sub(Fix64V1.ONE, t);
        int64 t1 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(t0, self.a.y)));
        int64 t2 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t, self.b.y))));
        int64 t3 = Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t0, Fix64V1.mul(Fix64V1.mul(t, t), self.c.y)));
        int64 t4 = Fix64V1.mul(t, Fix64V1.mul(t, Fix64V1.mul(t, self.d.y)));

        return Fix64V1.add(Fix64V1.add(t1, t2), Fix64V1.add(t3, t4));        
    }

    function mx(Bezier memory self,int64 t) internal pure returns (int64) {
        return xFunc(self, map(self, t));
    }

    function my(Bezier memory self,int64 t) internal pure returns (int64) {
        return yFunc(self, map(self, t));
    }

    function map(Bezier memory self, int64 t) private pure returns (int64) {
        int64 h = Fix64V1.mul(t, self.arcLengths[uint32(self.len)]);
        int32 n = 0;
        int32 s = 0;
        for (int32 i = self.len; s < i;)
        {
            n = s + ((i - s) / 2 | 0);
            if (self.arcLengths[uint32(n)] < h)
            {
                s = n + 1;
            }
            else
            {
                i = n;
            }
        }
        if (self.arcLengths[uint32(n)] > h)
        {
            n--;
        }
        int64 r = self.arcLengths[uint32(n)];
        return r == h ? Fix64V1.div(n * Fix64V1.ONE, self.len * Fix64V1.ONE) :
            Fix64V1.div(
                Fix64V1.add(n * Fix64V1.ONE, Fix64V1.div(Fix64V1.sub(h, r), Fix64V1.sub(self.arcLengths[uint32(n + 1)], r))),
                self.len * Fix64V1.ONE);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Star {
    int32 x;
    int32 y;
    int32 s;
    int32 c;
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

enum VertexStatus {
    Initial,
    Accumulate,
    Generate
}

enum LineCap {
    Butt,
    Square,
    Round
}

enum LineJoin {
    Miter,
    MiterRevert,
    Round,
    Bevel,
    MiterRound
}

enum Justification {
    Left,
    Center,
    Right
}

enum Command {
    Stop,
    MoveTo,
    LineTo,
    Curve3,
    Curve4,
    EndPoly
}

enum StrokeStatus {
    Initial,
    Ready,
    Cap1,
    Cap2,
    Outline1,
    CloseFirst,
    Outline2,
    OutVertices,
    EndPoly1,
    EndPoly2,
    Stop
}

enum ScanlineStatus {
    Initial,
    MoveTo,
    LineTo,
    Closed
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

/*
    Provides mathematical operations and representation in Q31.Q32 format.

    exp: Adapted from Petteri Aimonen's libfixmath
    
    See: https://github.com/PetteriAimonen/libfixmath
         https://github.com/PetteriAimonen/libfixmath/blob/master/LICENSE

    other functions: Adapted from André Slupik's FixedMath.NET
                     https://github.com/asik/FixedMath.Net/blob/master/LICENSE.txt
         
    THIRD PARTY NOTICES:
    ====================

    libfixmath is Copyright (c) 2011-2021 Flatmush <[email protected]>,
    Petteri Aimonen <[email protected]>, & libfixmath AUTHORS

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Copyright 2012 André Slupik

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This project uses code from the log2fix library, which is under the following license:           
    The MIT License (MIT)

    Copyright (c) 2015 Dan Moulding
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

library Fix64V1 {
    int64 public constant FRACTIONAL_PLACES = 32;
    int64 public constant ONE = 4294967296; // 1 << FRACTIONAL_PLACES
    int64 public constant TWO = ONE * 2;
    int64 public constant THREE = ONE * 3;
    int64 public constant PI = 0x3243F6A88;
    int64 public constant TWO_PI = 0x6487ED511;
    int64 public constant MAX_VALUE = type(int64).max;
    int64 public constant MIN_VALUE = type(int64).min;
    int64 public constant PI_OVER_2 = 0x1921FB544;

    function countLeadingZeros(uint64 x) internal pure returns (int64) {
        int64 result = 0;
        while ((x & 0xF000000000000000) == 0) {
            result += 4;
            x <<= 4;
        }
        while ((x & 0x8000000000000000) == 0) {
            result += 1;
            x <<= 1;
        }
        return result;
    }

    function div(int64 x, int64 y) internal pure returns (int64) {
        if (y == 0) {
            revert("attempted to divide by zero");
        }

        int64 xl = x;
        int64 yl = y;

        uint64 remainder = uint64(xl >= 0 ? xl : -xl);
        uint64 divider = uint64((yl >= 0 ? yl : -yl));
        uint64 quotient = 0;
        int64 bitPos = 64 / 2 + 1;

        while ((divider & 0xF) == 0 && bitPos >= 4) {
            divider >>= 4;
            bitPos -= 4;
        }

        while (remainder != 0 && bitPos >= 0) {
            int64 shift = countLeadingZeros(remainder);
            if (shift > bitPos) {
                shift = bitPos;
            }
            remainder <<= uint64(shift);
            bitPos -= shift;

            uint64 d = remainder / divider;
            remainder = remainder % divider;
            quotient += d << uint64(bitPos);

            if ((d & ~(uint64(0xFFFFFFFFFFFFFFFF) >> uint64(bitPos)) != 0)) {
                return ((xl ^ yl) & MIN_VALUE) == 0 ? MAX_VALUE : MIN_VALUE;
            }

            remainder <<= 1;
            --bitPos;
        }

        ++quotient;
        int64 result = int64(quotient >> 1);
        if (((xl ^ yl) & MIN_VALUE) != 0) {
            result = -result;
        }

        return int64(result);
    }

    function mul(int64 x, int64 y) internal pure returns (int64) {
        int64 xl = x;
        int64 yl = y;

        uint64 xlo = (uint64)((xl & (int64)(0x00000000FFFFFFFF)));
        int64 xhi = xl >> 32; // FRACTIONAL_PLACES
        uint64 ylo = (uint64)(yl & (int64)(0x00000000FFFFFFFF));
        int64 yhi = yl >> 32; // FRACTIONAL_PLACES

        uint64 lolo = xlo * ylo;
        int64 lohi = int64(xlo) * yhi;
        int64 hilo = xhi * int64(ylo);
        int64 hihi = xhi * yhi;

        uint64 loResult = lolo >> 32; // FRACTIONAL_PLACES
        int64 midResult1 = lohi;
        int64 midResult2 = hilo;
        int64 hiResult = hihi << 32; // FRACTIONAL_PLACES

        int64 sum = int64(loResult) + midResult1 + midResult2 + hiResult;

        return int64(sum);
    }

    function mul_256(int256 x, int256 y) internal pure returns (int256) {
        int256 xl = x;
        int256 yl = y;

        uint256 xlo = uint256((xl & int256(0x00000000FFFFFFFF)));
        int256 xhi = xl >> 32; // FRACTIONAL_PLACES
        uint256 ylo = uint256(yl & int256(0x00000000FFFFFFFF));
        int256 yhi = yl >> 32; // FRACTIONAL_PLACES

        uint256 lolo = xlo * ylo;
        int256 lohi = int256(xlo) * yhi;
        int256 hilo = xhi * int256(ylo);
        int256 hihi = xhi * yhi;

        uint256 loResult = lolo >> 32; // FRACTIONAL_PLACES
        int256 midResult1 = lohi;
        int256 midResult2 = hilo;
        int256 hiResult = hihi << 32; // FRACTIONAL_PLACES

        int256 sum = int256(loResult) + midResult1 + midResult2 + hiResult;

        return sum;
    }

    function floor(int256 x) internal pure returns (int64) {
        return int64(x & 0xFFFFFFFF00000000);
    }

    function round(int256 x) internal pure returns (int256) {
        int256 fractionalPart = x & 0x00000000FFFFFFFF;
        int256 integralPart = floor(x);
        if (fractionalPart < 0x80000000) return integralPart;
        if (fractionalPart > 0x80000000) return integralPart + ONE;
        if ((integralPart & ONE) == 0) return integralPart;
        return integralPart + ONE;
    }

    function sub(int64 x, int64 y) internal pure returns (int64) {
        int64 xl = x;
        int64 yl = y;
        int64 diff = xl - yl;
        if (((xl ^ yl) & (xl ^ diff) & MIN_VALUE) != 0)
            diff = xl < 0 ? MIN_VALUE : MAX_VALUE;
        return diff;
    }

    function add(int64 x, int64 y) internal pure returns (int64) {
        int64 xl = x;
        int64 yl = y;
        int64 sum = xl + yl;
        if ((~(xl ^ yl) & (xl ^ sum) & MIN_VALUE) != 0)
            sum = xl > 0 ? MAX_VALUE : MIN_VALUE;
        return sum;
    }

    function sign(int64 x) internal pure returns (int8) {
        return x == int8(0) ? int8(0) : x > int8(0) ? int8(1) : int8(-1);
    }

    function abs(int64 x) internal pure returns (int64) {
        int64 mask = x >> 63;
        return (x + mask) ^ mask;
    }

    function max(int64 a, int64 b) internal pure returns (int64) {
        return a >= b ? a : b;
    }

    function min(int64 a, int64 b) internal pure returns (int64) {
        return a < b ? a : b;
    }

    function map(
        int64 n,
        int64 start1,
        int64 stop1,
        int64 start2,
        int64 stop2
    ) internal pure returns (int64) {
        int64 value = mul(
            div(sub(n, start1), sub(stop1, start1)),
            add(sub(stop2, start2), start2)
        );

        return
            start2 < stop2
                ? constrain(value, start2, stop2)
                : constrain(value, stop2, start2);
    }

    function constrain(
        int64 n,
        int64 low,
        int64 high
    ) internal pure returns (int64) {
        return max(min(n, high), low);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./SinLut256.sol";

/*
    Provides trigonometric functions in Q31.Q32 format.

    exp: Adapted from Petteri Aimonen's libfixmath

    See: https://github.com/PetteriAimonen/libfixmath
         https://github.com/PetteriAimonen/libfixmath/blob/master/LICENSE

    other functions: Adapted from André Slupik's FixedMath.NET
                     https://github.com/asik/FixedMath.Net/blob/master/LICENSE.txt
         
    THIRD PARTY NOTICES:
    ====================

    libfixmath is Copyright (c) 2011-2021 Flatmush <[email protected]>,
    Petteri Aimonen <[email protected]>, & libfixmath AUTHORS

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Copyright 2012 André Slupik

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This project uses code from the log2fix library, which is under the following license:           
    The MIT License (MIT)

    Copyright (c) 2015 Dan Moulding
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

library Trig256 {
    int64 private constant LARGE_PI = 7244019458077122842;
    int64 private constant LN2 = 0xB17217F7;
    int64 private constant LN_MAX = 0x157CD0E702;
    int64 private constant LN_MIN = -0x162E42FEFA;
    int64 private constant E = -0x2B7E15162;

    function sin(int64 x) internal pure returns (int64) {
        (int64 clamped, bool flipHorizontal, bool flipVertical) = clamp(x);

        int64 lutInterval = Fix64V1.div(
            ((256 - 1) * Fix64V1.ONE),
            Fix64V1.PI_OVER_2
        );
        int256 rawIndex = Fix64V1.mul_256(clamped, lutInterval);
        int64 roundedIndex = int64(Fix64V1.round(rawIndex));
        int64 indexError = Fix64V1.sub(int64(rawIndex), roundedIndex);

        roundedIndex = roundedIndex >> 32; /* FRACTIONAL_PLACES */

        int64 nearestValueIndex = flipHorizontal
            ? (256 - 1) - roundedIndex
            : roundedIndex;

        int64 nearestValue = SinLut256.sinlut(nearestValueIndex);

        int64 secondNearestValue = SinLut256.sinlut(
            flipHorizontal
                ? (256 - 1) - roundedIndex - Fix64V1.sign(indexError)
                : roundedIndex + Fix64V1.sign(indexError)
        );

        int64 delta = Fix64V1.mul(
            indexError,
            Fix64V1.abs(Fix64V1.sub(nearestValue, secondNearestValue))
        );
        int64 interpolatedValue = nearestValue +
            (flipHorizontal ? -delta : delta);
        int64 finalValue = flipVertical
            ? -interpolatedValue
            : interpolatedValue;

        return finalValue;
    }

    function cos(int64 x) internal pure returns (int64) {
        int64 xl = x;
        int64 angle;
        if (xl > 0) {
            angle = Fix64V1.add(
                xl,
                Fix64V1.sub(0 - Fix64V1.PI, Fix64V1.PI_OVER_2)
            );
        } else {
            angle = Fix64V1.add(xl, Fix64V1.PI_OVER_2);
        }
        return sin(angle);
    }

    function sqrt(int64 x) internal pure returns (int64) {
        int64 xl = x;
        if (xl < 0) revert("negative value passed to sqrt");

        uint64 num = uint64(xl);
        uint64 result = uint64(0);
        uint64 bit = uint64(1) << (64 - 2);

        while (bit > num) bit >>= 2;
        for (uint8 i = 0; i < 2; ++i) {
            while (bit != 0) {
                if (num >= result + bit) {
                    num -= result + bit;
                    result = (result >> 1) + bit;
                } else {
                    result = result >> 1;
                }

                bit >>= 2;
            }

            if (i == 0) {
                if (num > (uint64(1) << (64 / 2)) - 1) {
                    num -= result;
                    num = (num << (64 / 2)) - uint64(0x80000000);
                    result = (result << (64 / 2)) + uint64(0x80000000);
                } else {
                    num <<= 64 / 2;
                    result <<= 64 / 2;
                }

                bit = uint64(1) << (64 / 2 - 2);
            }
        }

        if (num > result) ++result;
        return int64(result);
    }

    function log2_256(int256 x) internal pure returns (int256) {
        if (x <= 0) {
            revert("negative value passed to log2_256");
        }

        // This implementation is based on Clay. S. Turner's fast binary logarithm
        // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
        //     Processing Mag., pp. 124,140, Sep. 2010.)

        int256 b = 1 << 31; // FRACTIONAL_PLACES - 1
        int256 y = 0;

        int256 rawX = x;
        while (rawX < Fix64V1.ONE) {
            rawX <<= 1;
            y -= Fix64V1.ONE;
        }

        while (rawX >= Fix64V1.ONE << 1) {
            rawX >>= 1;
            y += Fix64V1.ONE;
        }

        int256 z = rawX;

        for (
            uint8 i = 0;
            i < 32; /* FRACTIONAL_PLACES */
            i++
        ) {
            z = Fix64V1.mul_256(z, z);
            if (z >= Fix64V1.ONE << 1) {
                z = z >> 1;
                y += b;
            }
            b >>= 1;
        }

        return y;
    }

    function log_256(int256 x) internal pure returns (int256) {
        return Fix64V1.mul_256(log2_256(x), LN2);
    }

    function log2(int64 x) internal pure returns (int64) {
        if (x <= 0) revert("non-positive value passed to log2");

        // This implementation is based on Clay. S. Turner's fast binary logarithm
        // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
        //     Processing Mag., pp. 124,140, Sep. 2010.)

        int64 b = 1 << 31; // FRACTIONAL_PLACES - 1
        int64 y = 0;

        int64 rawX = x;
        while (rawX < Fix64V1.ONE) {
            rawX <<= 1;
            y -= Fix64V1.ONE;
        }

        while (rawX >= Fix64V1.ONE << 1) {
            rawX >>= 1;
            y += Fix64V1.ONE;
        }

        int64 z = rawX;

        for (int32 i = 0; i < Fix64V1.FRACTIONAL_PLACES; i++) {
            z = Fix64V1.mul(z, z);
            if (z >= Fix64V1.ONE << 1) {
                z = z >> 1;
                y += b;
            }

            b >>= 1;
        }

        return y;
    }

    function log(int64 x) internal pure returns (int64) {
        return Fix64V1.mul(log2(x), LN2);
    }

    function exp(int64 x) internal pure returns (int64) {
        if (x == 0) return Fix64V1.ONE;
        if (x == Fix64V1.ONE) return E;
        if (x >= LN_MAX) return Fix64V1.MAX_VALUE;
        if (x <= LN_MIN) return 0;

        /* The algorithm is based on the power series for exp(x):
         * http://en.wikipedia.org/wiki/Exponential_function#Formal_definition
         *
         * From term n, we get term n+1 by multiplying with x/n.
         * When the sum term drops to zero, we can stop summing.
         */

        // The power-series converges much faster on positive values
        // and exp(-x) = 1/exp(x).

        bool neg = (x < 0);
        if (neg) x = -x;

        int64 result = Fix64V1.add(int64(x), Fix64V1.ONE);
        int64 term = x;

        for (uint32 i = 2; i < 40; i++) {
            term = Fix64V1.mul(x, Fix64V1.div(term, int32(i) * Fix64V1.ONE));
            result = Fix64V1.add(result, int64(term));
            if (term == 0) break;
        }

        if (neg) {
            result = Fix64V1.div(Fix64V1.ONE, result);
        }

        return result;
    }

    function clamp(int64 x)
        internal
        pure
        returns (
            int64,
            bool,
            bool
        )
    {
        int64 clamped2Pi = x;
        for (uint8 i = 0; i < 29; ++i) {
            clamped2Pi %= LARGE_PI >> i;
        }
        if (x < 0) {
            clamped2Pi += Fix64V1.TWO_PI;
        }

        bool flipVertical = clamped2Pi >= Fix64V1.PI;
        int64 clampedPi = clamped2Pi;
        while (clampedPi >= Fix64V1.PI) {
            clampedPi -= Fix64V1.PI;
        }

        bool flipHorizontal = clampedPi >= Fix64V1.PI_OVER_2;

        int64 clampedPiOver2 = clampedPi;
        if (clampedPiOver2 >= Fix64V1.PI_OVER_2)
            clampedPiOver2 -= Fix64V1.PI_OVER_2;

        return (clampedPiOver2, flipHorizontal, flipVertical);
    }

    function acos(int64 x) internal pure returns (int64 result) {
        if (x < -Fix64V1.ONE || x > Fix64V1.ONE) revert("invalid range for x");
        if (x == 0) return Fix64V1.PI_OVER_2;

        int64 t1 = Fix64V1.ONE - Fix64V1.mul(x, x);
        int64 t2 = Fix64V1.div(sqrt(t1), x);

        result = atan(t2);
        return x < 0 ? result + Fix64V1.PI : result;
    }

    function atan(int64 z) internal pure returns (int64 result) {
        if (z == 0) return 0;

        bool neg = z < 0;
        if (neg) z = -z;

        int64 two = Fix64V1.TWO;
        int64 three = Fix64V1.THREE;

        bool invert = z > Fix64V1.ONE;
        if (invert) z = Fix64V1.div(Fix64V1.ONE, z);

        result = Fix64V1.ONE;
        int64 term = Fix64V1.ONE;

        int64 zSq = Fix64V1.mul(z, z);
        int64 zSq2 = Fix64V1.mul(zSq, two);
        int64 zSqPlusOne = Fix64V1.add(zSq, Fix64V1.ONE);
        int64 zSq12 = Fix64V1.mul(zSqPlusOne, two);
        int64 dividend = zSq2;
        int64 divisor = Fix64V1.mul(zSqPlusOne, three);

        for (uint8 i = 2; i < 30; ++i) {
            term = Fix64V1.mul(term, Fix64V1.div(dividend, divisor));
            result = Fix64V1.add(result, term);

            dividend = Fix64V1.add(dividend, zSq2);
            divisor = Fix64V1.add(divisor, zSq12);

            if (term == 0) break;
        }

        result = Fix64V1.mul(result, Fix64V1.div(z, zSqPlusOne));

        if (invert) {
            result = Fix64V1.sub(Fix64V1.PI_OVER_2, result);
        }

        if (neg) {
            result = -result;
        }

        return result;
    }

    function atan2(int64 y, int64 x) internal pure returns (int64 result) {
        int64 e = 1202590848; /* 0.28 */
        int64 yl = y;
        int64 xl = x;

        if (xl == 0) {
            if (yl > 0) {
                return Fix64V1.PI_OVER_2;
            }
            if (yl == 0) {
                return 0;
            }
            return -Fix64V1.PI_OVER_2;
        }

        int64 z = Fix64V1.div(y, x);

        if (
            Fix64V1.add(Fix64V1.ONE, Fix64V1.mul(e, Fix64V1.mul(z, z))) ==
            type(int64).max
        ) {
            return y < 0 ? -Fix64V1.PI_OVER_2 : Fix64V1.PI_OVER_2;
        }

        if (Fix64V1.abs(z) < Fix64V1.ONE) {
            result = Fix64V1.div(
                z,
                Fix64V1.add(Fix64V1.ONE, Fix64V1.mul(e, Fix64V1.mul(z, z)))
            );
            if (xl < 0) {
                if (yl < 0) {
                    return Fix64V1.sub(result, Fix64V1.PI);
                }

                return Fix64V1.add(result, Fix64V1.PI);
            }
        } else {
            result = Fix64V1.sub(
                Fix64V1.PI_OVER_2,
                Fix64V1.div(z, Fix64V1.add(Fix64V1.mul(z, z), e))
            );

            if (yl < 0) {
                return Fix64V1.sub(result, Fix64V1.PI);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community Inc. All rights reserved. */

pragma solidity ^0.8.13;

library SinLut256 {
    /**
     * @notice Lookup tables for computing the sine value for a given angle.
     * @param i The clamped and rounded angle integral to index into the table.
     * @return The sine value in fixed-point (Q31.32) space.
     */
    function sinlut(int256 i) external pure returns (int64) {
        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) {
                                        return 0;
                                    } else {
                                        return 26456769;
                                    }
                                } else {
                                    if (i == 2) {
                                        return 52912534;
                                    } else {
                                        return 79366292;
                                    }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) {
                                        return 105817038;
                                    } else {
                                        return 132263769;
                                    }
                                } else {
                                    if (i == 6) {
                                        return 158705481;
                                    } else {
                                        return 185141171;
                                    }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) {
                                        return 211569835;
                                    } else {
                                        return 237990472;
                                    }
                                } else {
                                    if (i == 10) {
                                        return 264402078;
                                    } else {
                                        return 290803651;
                                    }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) {
                                        return 317194190;
                                    } else {
                                        return 343572692;
                                    }
                                } else {
                                    if (i == 14) {
                                        return 369938158;
                                    } else {
                                        return 396289586;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) {
                                        return 422625977;
                                    } else {
                                        return 448946331;
                                    }
                                } else {
                                    if (i == 18) {
                                        return 475249649;
                                    } else {
                                        return 501534935;
                                    }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) {
                                        return 527801189;
                                    } else {
                                        return 554047416;
                                    }
                                } else {
                                    if (i == 22) {
                                        return 580272619;
                                    } else {
                                        return 606475804;
                                    }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) {
                                        return 632655975;
                                    } else {
                                        return 658812141;
                                    }
                                } else {
                                    if (i == 26) {
                                        return 684943307;
                                    } else {
                                        return 711048483;
                                    }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) {
                                        return 737126679;
                                    } else {
                                        return 763176903;
                                    }
                                } else {
                                    if (i == 30) {
                                        return 789198169;
                                    } else {
                                        return 815189489;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) {
                                        return 841149875;
                                    } else {
                                        return 867078344;
                                    }
                                } else {
                                    if (i == 34) {
                                        return 892973912;
                                    } else {
                                        return 918835595;
                                    }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) {
                                        return 944662413;
                                    } else {
                                        return 970453386;
                                    }
                                } else {
                                    if (i == 38) {
                                        return 996207534;
                                    } else {
                                        return 1021923881;
                                    }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) {
                                        return 1047601450;
                                    } else {
                                        return 1073239268;
                                    }
                                } else {
                                    if (i == 42) {
                                        return 1098836362;
                                    } else {
                                        return 1124391760;
                                    }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) {
                                        return 1149904493;
                                    } else {
                                        return 1175373592;
                                    }
                                } else {
                                    if (i == 46) {
                                        return 1200798091;
                                    } else {
                                        return 1226177026;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) {
                                        return 1251509433;
                                    } else {
                                        return 1276794351;
                                    }
                                } else {
                                    if (i == 50) {
                                        return 1302030821;
                                    } else {
                                        return 1327217884;
                                    }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) {
                                        return 1352354586;
                                    } else {
                                        return 1377439973;
                                    }
                                } else {
                                    if (i == 54) {
                                        return 1402473092;
                                    } else {
                                        return 1427452994;
                                    }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) {
                                        return 1452378731;
                                    } else {
                                        return 1477249357;
                                    }
                                } else {
                                    if (i == 58) {
                                        return 1502063928;
                                    } else {
                                        return 1526821503;
                                    }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) {
                                        return 1551521142;
                                    } else {
                                        return 1576161908;
                                    }
                                } else {
                                    if (i == 62) {
                                        return 1600742866;
                                    } else {
                                        return 1625263084;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) {
                                        return 1649721630;
                                    } else {
                                        return 1674117578;
                                    }
                                } else {
                                    if (i == 66) {
                                        return 1698450000;
                                    } else {
                                        return 1722717974;
                                    }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) {
                                        return 1746920580;
                                    } else {
                                        return 1771056897;
                                    }
                                } else {
                                    if (i == 70) {
                                        return 1795126012;
                                    } else {
                                        return 1819127010;
                                    }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) {
                                        return 1843058980;
                                    } else {
                                        return 1866921015;
                                    }
                                } else {
                                    if (i == 74) {
                                        return 1890712210;
                                    } else {
                                        return 1914431660;
                                    }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) {
                                        return 1938078467;
                                    } else {
                                        return 1961651733;
                                    }
                                } else {
                                    if (i == 78) {
                                        return 1985150563;
                                    } else {
                                        return 2008574067;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) {
                                        return 2031921354;
                                    } else {
                                        return 2055191540;
                                    }
                                } else {
                                    if (i == 82) {
                                        return 2078383740;
                                    } else {
                                        return 2101497076;
                                    }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) {
                                        return 2124530670;
                                    } else {
                                        return 2147483647;
                                    }
                                } else {
                                    if (i == 86) {
                                        return 2170355138;
                                    } else {
                                        return 2193144275;
                                    }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) {
                                        return 2215850191;
                                    } else {
                                        return 2238472027;
                                    }
                                } else {
                                    if (i == 90) {
                                        return 2261008923;
                                    } else {
                                        return 2283460024;
                                    }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) {
                                        return 2305824479;
                                    } else {
                                        return 2328101438;
                                    }
                                } else {
                                    if (i == 94) {
                                        return 2350290057;
                                    } else {
                                        return 2372389494;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) {
                                        return 2394398909;
                                    } else {
                                        return 2416317469;
                                    }
                                } else {
                                    if (i == 98) {
                                        return 2438144340;
                                    } else {
                                        return 2459878695;
                                    }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) {
                                        return 2481519710;
                                    } else {
                                        return 2503066562;
                                    }
                                } else {
                                    if (i == 102) {
                                        return 2524518435;
                                    } else {
                                        return 2545874514;
                                    }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) {
                                        return 2567133990;
                                    } else {
                                        return 2588296054;
                                    }
                                } else {
                                    if (i == 106) {
                                        return 2609359905;
                                    } else {
                                        return 2630324743;
                                    }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) {
                                        return 2651189772;
                                    } else {
                                        return 2671954202;
                                    }
                                } else {
                                    if (i == 110) {
                                        return 2692617243;
                                    } else {
                                        return 2713178112;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) {
                                        return 2733636028;
                                    } else {
                                        return 2753990216;
                                    }
                                } else {
                                    if (i == 114) {
                                        return 2774239903;
                                    } else {
                                        return 2794384321;
                                    }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) {
                                        return 2814422705;
                                    } else {
                                        return 2834354295;
                                    }
                                } else {
                                    if (i == 118) {
                                        return 2854178334;
                                    } else {
                                        return 2873894071;
                                    }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) {
                                        return 2893500756;
                                    } else {
                                        return 2912997648;
                                    }
                                } else {
                                    if (i == 122) {
                                        return 2932384004;
                                    } else {
                                        return 2951659090;
                                    }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) {
                                        return 2970822175;
                                    } else {
                                        return 2989872531;
                                    }
                                } else {
                                    if (i == 126) {
                                        return 3008809435;
                                    } else {
                                        return 3027632170;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) {
                                        return 3046340019;
                                    } else {
                                        return 3064932275;
                                    }
                                } else {
                                    if (i == 130) {
                                        return 3083408230;
                                    } else {
                                        return 3101767185;
                                    }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) {
                                        return 3120008443;
                                    } else {
                                        return 3138131310;
                                    }
                                } else {
                                    if (i == 134) {
                                        return 3156135101;
                                    } else {
                                        return 3174019130;
                                    }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) {
                                        return 3191782721;
                                    } else {
                                        return 3209425199;
                                    }
                                } else {
                                    if (i == 138) {
                                        return 3226945894;
                                    } else {
                                        return 3244344141;
                                    }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) {
                                        return 3261619281;
                                    } else {
                                        return 3278770658;
                                    }
                                } else {
                                    if (i == 142) {
                                        return 3295797620;
                                    } else {
                                        return 3312699523;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) {
                                        return 3329475725;
                                    } else {
                                        return 3346125588;
                                    }
                                } else {
                                    if (i == 146) {
                                        return 3362648482;
                                    } else {
                                        return 3379043779;
                                    }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) {
                                        return 3395310857;
                                    } else {
                                        return 3411449099;
                                    }
                                } else {
                                    if (i == 150) {
                                        return 3427457892;
                                    } else {
                                        return 3443336630;
                                    }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) {
                                        return 3459084709;
                                    } else {
                                        return 3474701532;
                                    }
                                } else {
                                    if (i == 154) {
                                        return 3490186507;
                                    } else {
                                        return 3505539045;
                                    }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) {
                                        return 3520758565;
                                    } else {
                                        return 3535844488;
                                    }
                                } else {
                                    if (i == 158) {
                                        return 3550796243;
                                    } else {
                                        return 3565613262;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) {
                                        return 3580294982;
                                    } else {
                                        return 3594840847;
                                    }
                                } else {
                                    if (i == 162) {
                                        return 3609250305;
                                    } else {
                                        return 3623522808;
                                    }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) {
                                        return 3637657816;
                                    } else {
                                        return 3651654792;
                                    }
                                } else {
                                    if (i == 166) {
                                        return 3665513205;
                                    } else {
                                        return 3679232528;
                                    }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) {
                                        return 3692812243;
                                    } else {
                                        return 3706251832;
                                    }
                                } else {
                                    if (i == 170) {
                                        return 3719550786;
                                    } else {
                                        return 3732708601;
                                    }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) {
                                        return 3745724777;
                                    } else {
                                        return 3758598821;
                                    }
                                } else {
                                    if (i == 174) {
                                        return 3771330243;
                                    } else {
                                        return 3783918561;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) {
                                        return 3796363297;
                                    } else {
                                        return 3808663979;
                                    }
                                } else {
                                    if (i == 178) {
                                        return 3820820141;
                                    } else {
                                        return 3832831319;
                                    }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) {
                                        return 3844697060;
                                    } else {
                                        return 3856416913;
                                    }
                                } else {
                                    if (i == 182) {
                                        return 3867990433;
                                    } else {
                                        return 3879417181;
                                    }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) {
                                        return 3890696723;
                                    } else {
                                        return 3901828632;
                                    }
                                } else {
                                    if (i == 186) {
                                        return 3912812484;
                                    } else {
                                        return 3923647863;
                                    }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) {
                                        return 3934334359;
                                    } else {
                                        return 3944871565;
                                    }
                                } else {
                                    if (i == 190) {
                                        return 3955259082;
                                    } else {
                                        return 3965496515;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) {
                                        return 3975583476;
                                    } else {
                                        return 3985519583;
                                    }
                                } else {
                                    if (i == 194) {
                                        return 3995304457;
                                    } else {
                                        return 4004937729;
                                    }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) {
                                        return 4014419032;
                                    } else {
                                        return 4023748007;
                                    }
                                } else {
                                    if (i == 198) {
                                        return 4032924300;
                                    } else {
                                        return 4041947562;
                                    }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) {
                                        return 4050817451;
                                    } else {
                                        return 4059533630;
                                    }
                                } else {
                                    if (i == 202) {
                                        return 4068095769;
                                    } else {
                                        return 4076503544;
                                    }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) {
                                        return 4084756634;
                                    } else {
                                        return 4092854726;
                                    }
                                } else {
                                    if (i == 206) {
                                        return 4100797514;
                                    } else {
                                        return 4108584696;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) {
                                        return 4116215977;
                                    } else {
                                        return 4123691067;
                                    }
                                } else {
                                    if (i == 210) {
                                        return 4131009681;
                                    } else {
                                        return 4138171544;
                                    }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) {
                                        return 4145176382;
                                    } else {
                                        return 4152023930;
                                    }
                                } else {
                                    if (i == 214) {
                                        return 4158713929;
                                    } else {
                                        return 4165246124;
                                    }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) {
                                        return 4171620267;
                                    } else {
                                        return 4177836117;
                                    }
                                } else {
                                    if (i == 218) {
                                        return 4183893437;
                                    } else {
                                        return 4189791999;
                                    }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) {
                                        return 4195531577;
                                    } else {
                                        return 4201111955;
                                    }
                                } else {
                                    if (i == 222) {
                                        return 4206532921;
                                    } else {
                                        return 4211794268;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) {
                                        return 4216895797;
                                    } else {
                                        return 4221837315;
                                    }
                                } else {
                                    if (i == 226) {
                                        return 4226618635;
                                    } else {
                                        return 4231239573;
                                    }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) {
                                        return 4235699957;
                                    } else {
                                        return 4239999615;
                                    }
                                } else {
                                    if (i == 230) {
                                        return 4244138385;
                                    } else {
                                        return 4248116110;
                                    }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) {
                                        return 4251932639;
                                    } else {
                                        return 4255587827;
                                    }
                                } else {
                                    if (i == 234) {
                                        return 4259081536;
                                    } else {
                                        return 4262413632;
                                    }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) {
                                        return 4265583990;
                                    } else {
                                        return 4268592489;
                                    }
                                } else {
                                    if (i == 238) {
                                        return 4271439015;
                                    } else {
                                        return 4274123460;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) {
                                        return 4276645722;
                                    } else {
                                        return 4279005706;
                                    }
                                } else {
                                    if (i == 242) {
                                        return 4281203321;
                                    } else {
                                        return 4283238485;
                                    }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) {
                                        return 4285111119;
                                    } else {
                                        return 4286821154;
                                    }
                                } else {
                                    if (i == 246) {
                                        return 4288368525;
                                    } else {
                                        return 4289753172;
                                    }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) {
                                        return 4290975043;
                                    } else {
                                        return 4292034091;
                                    }
                                } else {
                                    if (i == 250) {
                                        return 4292930277;
                                    } else {
                                        return 4293663567;
                                    }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) {
                                        return 4294233932;
                                    } else {
                                        return 4294641351;
                                    }
                                } else {
                                    if (i == 254) {
                                        return 4294885809;
                                    } else {
                                        return 4294967296;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./_Structs.sol";
import "./Fix64V1.sol";
import "./AntiAlias.sol";
import "./SubpixelScale.sol";
import "./RectangleInt.sol";
import "./Matrix.sol";
import "./ScanlineData.sol";
import "./ClippingData.sol";
import "./CellData.sol";
import "./Clipping.sol";
import "./PixelClipping.sol";
import "./ColorMath.sol";
import "./ApplyTransform.sol";
import "./ScanlineRasterizer.sol";

struct Graphics2D {
    AntiAlias aa;
    SubpixelScale ss;
    ScanlineData scanlineData;
    ClippingData clippingData;
    CellData cellData;
    uint8[] buffer;
    uint32 width;
    uint32 height;
}

library Graphics2DMethods {
    int32 public constant OrderB = 0;
    int32 public constant OrderG = 1;
    int32 public constant OrderR = 2;
    int32 public constant OrderA = 3;

    function create(uint32 width, uint32 height)
        external
        pure
        returns (Graphics2D memory g)
    {
        g.width = width;
        g.height = height;

        g.aa = AntiAliasMethods.create(8);
        g.ss = SubpixelScaleMethods.create(8);
        g.scanlineData = ScanlineDataMethods.create(g.aa);
        g.clippingData = ClippingDataMethods.create(width, height, g.ss);
        g.cellData = CellDataMethods.create();
        g.buffer = new uint8[](width * 4 * height);
    }

    function clear(Graphics2D memory g, uint32 color)
        internal
        pure
    {
        int32 scale = int32(g.ss.scale);

        RectangleInt memory clippingRect = RectangleInt(
            g.clippingData.clipBox.left / scale,
            g.clippingData.clipBox.bottom / scale,
            g.clippingData.clipBox.right / scale,
            g.clippingData.clipBox.top / scale
        );

        for (int32 y = clippingRect.bottom; y < clippingRect.top; y++) {
            int32 bufferOffset = getBufferOffsetXy(g, clippingRect.left, y);

            for (int32 x = 0; x < clippingRect.right - clippingRect.left; x++) {
                g.buffer[uint32(bufferOffset + OrderB)] = uint8(color >> 0);
                g.buffer[uint32(bufferOffset + OrderG)] = uint8(color >> 8);
                g.buffer[uint32(bufferOffset + OrderR)] = uint8(color >> 16);
                g.buffer[uint32(bufferOffset + OrderA)] = uint8(color >> 24);
                bufferOffset += 4;
            }
        }
    }

    function renderWithTransform(
        Graphics2D memory g,
        VertexData[] memory vertices,
        uint32 color,
        Matrix memory transform,
        bool blend
    ) internal pure {
        if (!MatrixMethods.isIdentity(transform)) {
            vertices = ApplyTransform.applyTransform(vertices, transform);
        }
        render_impl(g, vertices, color, blend);
    }

    function render(
        Graphics2D memory g,
        VertexData[] memory vertices,
        uint32 color,
        bool blend
    ) internal pure {
        render_impl(g, vertices, color, blend);
    }

    function render_impl(
        Graphics2D memory g,
        VertexData[] memory vertices,
        uint32 color,
        bool blend
    ) private pure {
        reset(g.scanlineData, g.cellData);
        addPath(g, vertices);
        if(g.cellData.used != 23) {
            revert ("pre-fail");
        }
        if (g.buffer.length != 0) {
            g = ScanlineRasterizer.renderSolid(g, color, blend);
        }
        if(g.cellData.used != 24) {
            revert ("post-fail");
        }
    }

    function getBufferOffsetY(Graphics2D memory g, int32 y)
        internal
        pure
        returns (int32)
    {
        return y * int32(g.width) * 4;
    }

    function getBufferOffsetXy(
        Graphics2D memory g,
        int32 x,
        int32 y
    ) internal pure returns (int32) {
        if (x < 0 || x >= int32(g.width) || y < 0 || y >= int32(g.height))
            return -1;
        return y * int32(g.width) * 4 + x * 4;
    }

    function copyPixels(
        uint8[] memory buffer,
        int32 bufferOffset,
        uint32 sourceColor,
        int32 count,
        PixelClipping memory clipping
    ) internal pure {
        int32 i = 0;
        do {
            if (
                clipping.area.length > 0 &&
                !PixelClippingMethods.isPointInPolygon(
                    clipping,
                    clipping.x + i,
                    clipping.y
                )
            ) {
                i++;
                bufferOffset += 4;
                continue;
            }

            buffer[uint32(bufferOffset + OrderR)] = uint8(sourceColor >> 16);
            buffer[uint32(bufferOffset + OrderG)] = uint8(sourceColor >> 8);
            buffer[uint32(bufferOffset + OrderB)] = uint8(sourceColor >> 0);
            buffer[uint32(bufferOffset + OrderA)] = uint8(sourceColor >> 24);
            bufferOffset += 4;
            i++;
        } while (--count != 0);
    }

    function blendPixel(
        uint8[] memory buffer,
        int32 bufferOffset,
        uint32 sourceColor,
        PixelClipping memory clipping
    ) internal pure {
        if (bufferOffset == -1) return;

        if (
            clipping.area.length > 0 &&
            !PixelClippingMethods.isPointInPolygon(
                clipping,
                clipping.x,
                clipping.y
            )
        ) {
            return;
        }

        {
            uint8 sr = uint8(sourceColor >> 16);
            uint8 sg = uint8(sourceColor >> 8);
            uint8 sb = uint8(sourceColor >> 0);
            uint8 sa = uint8(sourceColor >> 24);

            unchecked
            {
                if (sourceColor >> 24 == 255)
                {
                    buffer[uint32(bufferOffset + OrderR)] = sr;
                    buffer[uint32(bufferOffset + OrderG)] = sg;
                    buffer[uint32(bufferOffset + OrderB)] = sb;
                    buffer[uint32(bufferOffset + OrderA)] = sa;
                }
                else
                {
                    int32 r = int32(uint32(buffer[uint32(bufferOffset + OrderR)]));
                    int32 g = int32(uint32(buffer[uint32(bufferOffset + OrderG)]));
                    int32 b = int32(uint32(buffer[uint32(bufferOffset + OrderB)]));
                    int32 a = int32(uint32(buffer[uint32(bufferOffset + OrderA)]));

                    buffer[uint32(bufferOffset + OrderR)] = uint8(uint32(((int32(uint32(sr)) - r) * int32(uint32(sa)) + (r << 8)) >> 8));
                    buffer[uint32(bufferOffset + OrderG)] = uint8(uint32(((int32(uint32(sg)) - g) * int32(uint32(sa)) + (g << 8)) >> 8));
                    buffer[uint32(bufferOffset + OrderB)] = uint8(uint32(((int32(uint32(sb)) - b) * int32(uint32(sa)) + (b << 8)) >> 8));
                    buffer[uint32(bufferOffset + OrderA)] = uint8(uint32(int32(uint32(sa)) + a - ((int32(uint32(sa)) * a + 255) >> 8)));
                }
            }
        }
    }

    function addPath(Graphics2D memory g, VertexData[] memory vertices)
        private
        pure
    {
        if (g.cellData.sorted) {
            reset(g.scanlineData, g.cellData);
        }

        for (uint32 i = 0; i < vertices.length; i++) {
            VertexData memory vertex = vertices[i];
            if (vertex.command == Command.Stop) break;

            Command command = vertex.command;

            if (command == Command.MoveTo) {
                if (g.cellData.sorted) reset(g.scanlineData, g.cellData);
                closePolygon(g);
                g.scanlineData.startX = ClippingDataMethods.upscale(vertex.position.x, g.ss);
                g.scanlineData.startY = ClippingDataMethods.upscale(vertex.position.y, g.ss);
                Clipping.moveToClip(g.scanlineData.startX, g.scanlineData.startY, g.clippingData);
                g.scanlineData.status = ScanlineStatus.MoveTo;
            } else {
                if (command != Command.Stop && command != Command.EndPoly) {
                    Clipping.lineToClip(g, ClippingDataMethods.upscale(vertex.position.x, g.ss), ClippingDataMethods.upscale(vertex.position.y, g.ss));
                    g.scanlineData.status = ScanlineStatus.LineTo;
                } else {
                    if (command == Command.EndPoly) closePolygon(g);
                }
            }
        }
    }

    function closePolygon(Graphics2D memory g) internal pure {
        if (g.scanlineData.status != ScanlineStatus.LineTo) {
            return;
        }
        Clipping.lineToClip(g, g.scanlineData.startX, g.scanlineData.startY);
        g.scanlineData.status = ScanlineStatus.Closed;
    }

    function reset(ScanlineData memory scanlineData, CellData memory cellData)
        private
        pure
    {
        CellRasterizer.resetCells(cellData);
        scanlineData.status = ScanlineStatus.Initial;
    }
}

contract TestGraphics2DMethods {
    function blendPixel(
        uint8[] memory buffer,
        int32 bufferOffset,
        uint32 sourceColor,
        PixelClipping memory clipping
    ) external pure returns (uint8[] memory) {
        Graphics2DMethods.blendPixel(buffer, bufferOffset, sourceColor, clipping);
        return buffer;
    }

    function copyPixels(
        uint8[] memory buffer,
        int32 bufferOffset,
        uint32 sourceColor,
        int32 count,
        PixelClipping memory clipping
    ) external pure returns (uint8[] memory) {
        Graphics2DMethods.copyPixels(buffer, bufferOffset, sourceColor, count, clipping);
        return buffer;
    }

    function createBufferOnly(uint32 width, uint32 height)
        external
        pure
        returns (Graphics2D memory g)
    {
        g.buffer = new uint8[](width * 4 * height);
    }

    function targetColorTest(int32 alpha, uint32 sourceColor) external pure returns (uint32 targetColor) {
        targetColor = ColorMath.toColor(uint8(uint32(alpha)), 
        uint8(sourceColor >> 16), 
        uint8(sourceColor >> 8), 
        uint8(sourceColor >> 0));
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

struct AntiAlias {
    uint32 value;
    uint32 scale;
    uint32 mask;
}

library AntiAliasMethods {
    function create(uint32 sampling)
        internal
        pure
        returns (AntiAlias memory aa)
    {
        aa.value = sampling;
        aa.scale = uint32(1) << aa.value;
        aa.mask = aa.scale - 1;
        return aa;
    }
}

contract TestAntiAliasMethods {
    function create(uint32 sampling)
        external
        pure
        returns (AntiAlias memory aa)
    {
        return AntiAliasMethods.create(sampling);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

struct SubpixelScale {
    uint32 value;
    uint32 scale;
    uint32 mask;
    uint32 dxLimit;
}

library SubpixelScaleMethods {
    function create(uint32 sampling)
        internal
        pure
        returns (SubpixelScale memory ss)
    {
        ss.value = sampling;
        ss.scale = uint32(1) << ss.value;
        ss.mask = ss.scale - 1;
        ss.dxLimit = uint32(16384) << ss.value;
        return ss;
    }
}

contract TestSubpixelScaleMethods {
    function create(uint32 sampling)
        external
        pure
        returns (SubpixelScale memory ss)
    {
        return SubpixelScaleMethods.create(sampling);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

struct RectangleInt {
    int32 left;
    int32 bottom;
    int32 right;
    int32 top;
}

library RectangleIntMethods {
    function normalize(RectangleInt memory rect) internal pure {
        int32 t;

        if (rect.left > rect.right) {
            t = rect.left;
            rect.left = rect.right;
            rect.right = t;
        }

        if (rect.bottom > rect.top) {
            t = rect.bottom;
            rect.bottom = rect.top;
            rect.top = t;
        }
    }
}

contract TestRectangleIntMethods {
    function normalize(RectangleInt memory rect) external pure returns(RectangleInt memory) {
        RectangleIntMethods.normalize(rect);
        return rect;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./Trig256.sol";
import "./_Structs.sol";
import "./MathUtils.sol";

struct Matrix {
    int64 sx;
    int64 shy;
    int64 shx;
    int64 sy;
    int64 tx;
    int64 ty;
}

library MatrixMethods {
    function newIdentity() internal pure returns (Matrix memory value) {
        value.sx = Fix64V1.ONE;
        value.shy = 0;
        value.shx = 0;
        value.sy = Fix64V1.ONE;
        value.tx = 0;
        value.ty = 0;
    }

    function newRotation(int64 radians) internal pure returns (Matrix memory) {
        int64 v0 = Trig256.cos(radians);
        int64 v1 = Trig256.sin(radians);
        int64 v2 = -Trig256.sin(radians);
        int64 v3 = Trig256.cos(radians);

        return Matrix(v0, v1, v2, v3, 0, 0);
    }

    function newScale(int64 scale) internal pure returns (Matrix memory) {
        return Matrix(scale, 0, 0, scale, 0, 0);
    }

    function newScale(int64 scaleX, int64 scaleY)
        internal
        pure
        returns (Matrix memory)
    {
        return Matrix(scaleX, 0, 0, scaleY, 0, 0);
    }

    function newTranslation(int64 x, int64 y)
        internal
        pure
        returns (Matrix memory)
    {
        return Matrix(Fix64V1.ONE, 0, 0, Fix64V1.ONE, x, y);
    }

    function transform(
        Matrix memory self,
        int64 x,
        int64 y
    ) internal pure returns (int64, int64) {
        int64 tmp = x;
        x = Fix64V1.add(
            Fix64V1.mul(tmp, self.sx),
            Fix64V1.add(Fix64V1.mul(y, self.shx), self.tx)
        );
        y = Fix64V1.add(
            Fix64V1.mul(tmp, self.shy),
            Fix64V1.add(Fix64V1.mul(y, self.sy), self.ty)
        );
        return (x, y);
    }

    function transform(Matrix memory self, Vector2 memory v)
        internal
        pure
        returns (Vector2 memory result)
    {
        result = v;
        transform(self, result.x, result.y);
        return result;
    }

    function invert(Matrix memory self) internal pure {
        int64 d = Fix64V1.div(
            Fix64V1.ONE,
            Fix64V1.sub(
                Fix64V1.mul(self.sx, self.sy),
                Fix64V1.mul(self.shy, self.shx)
            )
        );

        self.sy = Fix64V1.mul(self.sx, d);
        self.shy = Fix64V1.mul(-self.shy, d);
        self.shx = Fix64V1.mul(-self.shx, d);

        self.ty = Fix64V1.sub(
            Fix64V1.mul(-self.tx, self.shy),
            Fix64V1.mul(self.ty, self.sy)
        );
        self.sx = Fix64V1.mul(self.sy, d);
        self.tx = Fix64V1.sub(
            Fix64V1.mul(-self.tx, Fix64V1.mul(self.sy, d)),
            Fix64V1.mul(self.ty, self.shx)
        );
    }

    function isIdentity(Matrix memory self) internal pure returns (bool) {
        return
            isEqual(self.sx, Fix64V1.ONE, MathUtils.Epsilon) &&
            isEqual(self.shy, 0, MathUtils.Epsilon) &&
            isEqual(self.shx, 0, MathUtils.Epsilon) &&
            isEqual(self.sy, Fix64V1.ONE, MathUtils.Epsilon) &&
            isEqual(self.tx, 0, MathUtils.Epsilon) &&
            isEqual(self.ty, 0, MathUtils.Epsilon);
    }

    function isEqual(
        int64 v1,
        int64 v2,
        int64 epsilon
    ) internal pure returns (bool) {
        return Fix64V1.abs(Fix64V1.sub(v1, v2)) <= epsilon;
    }

    function mul(Matrix memory self, Matrix memory other)
        internal
        pure
        returns (Matrix memory)
    {
        int64 t0 = Fix64V1.add(
            Fix64V1.mul(self.sx, other.sx),
            Fix64V1.mul(self.shy, other.shx)
        );
        int64 t1 = Fix64V1.add(
            Fix64V1.mul(self.shx, other.sx),
            Fix64V1.mul(self.sy, other.shx)
        );
        int64 t2 = Fix64V1.add(
            Fix64V1.mul(self.tx, other.sx),
            Fix64V1.add(Fix64V1.mul(self.ty, other.shx), other.tx)
        );
        int64 t3 = Fix64V1.add(
            Fix64V1.mul(self.sx, other.shy),
            Fix64V1.mul(self.shy, other.sy)
        );
        int64 t4 = Fix64V1.add(
            Fix64V1.mul(self.shx, other.shy),
            Fix64V1.mul(self.sy, other.sy)
        );
        int64 t5 = Fix64V1.add(
            Fix64V1.mul(self.tx, other.shy),
            Fix64V1.add(Fix64V1.mul(self.ty, other.sy), other.ty)
        );

        self.shy = t3;
        self.sy = t4;
        self.ty = t5;
        self.sx = t0;
        self.shx = t1;
        self.tx = t2;

        return self;
    }
}

contract TestMatrixMethods {
    function mul(Matrix memory self, Matrix memory other)
        external
        pure
        returns (Matrix memory)
    {
        return MatrixMethods.mul(self, other);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./_Enums.sol";
import "./_Structs.sol";
import "./AntiAlias.sol";

struct ScanlineData {
    int32[] gamma;
    int32 scanY;
    int32 startX;
    int32 startY;
    ScanlineStatus status;
    int32 coverIndex;
    uint8[] covers;
    int32 spanIndex;
    ScanlineSpan[] spans;
    int32 current;
    int32 lastX;
    int32 y;
}

library ScanlineDataMethods {
    function create(AntiAlias memory aa)
        internal
        pure
        returns (ScanlineData memory scanlineData)
    {
        scanlineData.startX = 0;
        scanlineData.startY = 0;
        scanlineData.status = ScanlineStatus.Initial;
        scanlineData.gamma = new int32[](aa.scale);
        for (uint32 i = 0; i < aa.scale; i++) {
            scanlineData.gamma[i] = int32(i);
        }
        scanlineData.lastX = 0x7FFFFFF0;
        scanlineData.covers = new uint8[](1000);
        scanlineData.spans = new ScanlineSpan[](1000);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Matrix.sol";
import "./RectangleInt.sol";
import "./SubpixelScale.sol";

struct ClippingData {
    int32 f1;
    int32 x1;
    int32 y1;
    Matrix clipTransform;
    Vector2[] clipPoly;
    RectangleInt clipBox;
    bool clipping;
}

library ClippingDataMethods {
    function create(
        uint32 width,
        uint32 height,
        SubpixelScale memory ss
    ) internal pure returns (ClippingData memory clippingData) {
        clippingData.x1 = 0;
        clippingData.y1 = 0;
        clippingData.f1 = 0;
        clippingData.clipBox = RectangleInt(
            0,
            0,
            upscale(int64(int32(width) * Fix64V1.ONE), ss),
            upscale(int64(int32(height) * Fix64V1.ONE), ss)
        );
        RectangleIntMethods.normalize(clippingData.clipBox);
        clippingData.clipping = true;
    }

    function upscale(int64 v, SubpixelScale memory ss)
        internal
        pure
        returns (int32)
    {
        return
            int32(
                Fix64V1.round(Fix64V1.mul(v, int32(ss.scale) * Fix64V1.ONE)) /
                    Fix64V1.ONE
            );
    }
}

contract TestClippingDataMethods {
    function create(
        uint32 width,
        uint32 height,
        SubpixelScale memory ss
    ) external pure returns (ClippingData memory clippingData) {
        return ClippingDataMethods.create(width, height, ss);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./_Structs.sol"; 
import "./Cell.sol";
import "./CellBlock.sol";

struct CellData {
    CellBlock cb;
    Cell[] cells;
    Cell current;
    uint32 used;
    SortedY[] sortedY;
    Cell[] sortedCells;
    bool sorted;
    Cell style;
    int32 minX;
    int32 maxX;
    int32 minY;
    int32 maxY;
}

library CellDataMethods {
    function create() internal pure returns (CellData memory cellData) {
        cellData.cb = CellBlockMethods.create(12);
        cellData.cells = new Cell[](cellData.cb.limit);
        cellData.sortedCells = new Cell[](0);
        cellData.sortedY = new SortedY[](0);
        cellData.sorted = false;
        cellData.style = CellMethods.create();
        cellData.current = CellMethods.create();
        cellData.minX = 0x7FFFFFFF;
        cellData.minY = 0x7FFFFFFF;
        cellData.maxX = -0x7FFFFFFF;
        cellData.maxY = -0x7FFFFFFF;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./RectangleInt.sol";
import "./SubpixelScale.sol";
import "./ClippingData.sol";
import "./CellData.sol";
import "./CellRasterizer.sol";
import "./Graphics2D.sol";

library Clipping {
    function noClippingBox(ClippingData memory clippingData) internal pure {
        clippingData.clipPoly = new Vector2[](0);
    }

    function setClippingBox(
        ClippingData memory clippingData,
        int32 left,
        int32 top,
        int32 right,
        int32 bottom,
        Matrix memory transform,
        int32 height
    ) internal pure {
        Vector2 memory tl = MatrixMethods.transform(
            transform,
            Vector2(left * Fix64V1.ONE, top * Fix64V1.ONE)
        );
        Vector2 memory tr = MatrixMethods.transform(
            transform,
            Vector2(right * Fix64V1.ONE, top * Fix64V1.ONE)
        );
        Vector2 memory br = MatrixMethods.transform(
            transform,
            Vector2(right * Fix64V1.ONE, bottom * Fix64V1.ONE)
        );
        Vector2 memory bl = MatrixMethods.transform(
            transform,
            Vector2(left * Fix64V1.ONE, bottom * Fix64V1.ONE)
        );

        clippingData.clipTransform = transform;
        clippingData.clipPoly = new Vector2[](4);
        clippingData.clipPoly[0] = Vector2(
            tl.x,
            Fix64V1.sub(height * Fix64V1.ONE, tl.y)
        );
        clippingData.clipPoly[1] = Vector2(
            tr.x,
            Fix64V1.sub(height * Fix64V1.ONE, tr.y)
        );
        clippingData.clipPoly[2] = Vector2(
            br.x,
            Fix64V1.sub(height * Fix64V1.ONE, br.y)
        );
        clippingData.clipPoly[3] = Vector2(
            bl.x,
            Fix64V1.sub(height * Fix64V1.ONE, bl.y)
        );
    }

    function moveToClip(
        int32 x1,
        int32 y1,
        ClippingData memory clippingData
    ) internal pure {
        clippingData.x1 = x1;
        clippingData.y1 = y1;
        if (clippingData.clipping) {
            clippingData.f1 = clippingFlags(x1, y1, clippingData.clipBox);        
        }
    }

    function lineToClip(
        Graphics2D memory g,
        int32 x2,
        int32 y2
    ) internal pure {
        if (g.clippingData.clipping) {
            int32 f2 = clippingFlags(x2, y2, g.clippingData.clipBox);

            if (
                (g.clippingData.f1 & 10) == (f2 & 10) &&
                (g.clippingData.f1 & 10) != 0
            ) {
                g.clippingData.x1 = x2;
                g.clippingData.y1 = y2;
                g.clippingData.f1 = f2;
                return;
            }

            int32 x1 = g.clippingData.x1;
            int32 y1 = g.clippingData.y1;
            int32 f1 = g.clippingData.f1;
            int32 y3;
            int32 y4;
            int32 f3;
            int32 f4;

            if ((((f1 & 5) << 1) | (f2 & 5)) == 0) {
                lineClipY(g, LineClipY(x1, y1, x2, y2, f1, f2));
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 1) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(x1, y1, g.clippingData.clipBox.right, y3, f1, f3)
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y3,
                        g.clippingData.clipBox.right,
                        y2,
                        f3,
                        f2
                    )
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 2) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y1,
                        g.clippingData.clipBox.right,
                        y3,
                        f1,
                        f3
                    )
                );
                lineClipY(
                    g,
                    LineClipY(g.clippingData.clipBox.right, y3, x2, y2, f3, f2)
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 3) {
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y1,
                        g.clippingData.clipBox.right,
                        y2,
                        f1,
                        f2
                    )
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 4) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(x1, y1, g.clippingData.clipBox.left, y3, f1, f3)
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y3,
                        g.clippingData.clipBox.left,
                        y2,
                        f3,
                        f2
                    )
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 6) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                y4 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                f4 = clippingFlagsY(y4, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y1,
                        g.clippingData.clipBox.right,
                        y3,
                        f1,
                        f3
                    )
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y3,
                        g.clippingData.clipBox.left,
                        y4,
                        f3,
                        f4
                    )
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y4,
                        g.clippingData.clipBox.left,
                        y2,
                        f4,
                        f2
                    )
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 8) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y1,
                        g.clippingData.clipBox.left,
                        y3,
                        f1,
                        f3
                    )
                );
                lineClipY(
                    g,
                    LineClipY(g.clippingData.clipBox.left, y3, x2, y2, f3, f2)
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 9) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                y4 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                f4 = clippingFlagsY(y4, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y1,
                        g.clippingData.clipBox.left,
                        y3,
                        f1,
                        f3
                    )
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y3,
                        g.clippingData.clipBox.right,
                        y4,
                        f3,
                        f4
                    )
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y4,
                        g.clippingData.clipBox.right,
                        y2,
                        f4,
                        f2
                    )
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 12) {
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y1,
                        g.clippingData.clipBox.left,
                        y2,
                        f1,
                        f2
                    )
                );
            }

            g.clippingData.f1 = f2;
        } else {
            CellRasterizer.line(
                CellRasterizer.Line(
                    g.clippingData.x1,
                    g.clippingData.y1,
                    x2,
                    y2
                ), g.cellData, g.ss);
        }

        g.clippingData.x1 = x2;
        g.clippingData.y1 = y2;
    }

    struct LineClipY {
        int32 x1;
        int32 y1;
        int32 x2;
        int32 y2;
        int32 f1;
        int32 f2;
    }

    function lineClipY(Graphics2D memory g, LineClipY memory f) private pure {
        f.f1 &= 10;
        f.f2 &= 10;
        if ((f.f1 | f.f2) == 0) {
            CellRasterizer.line(CellRasterizer.Line(f.x1, f.y1, f.x2, f.y2), g.cellData, g.ss);
        } else {
            if (f.f1 == f.f2)
                return;

            int32 tx1 = f.x1;
            int32 ty1 = f.y1;
            int32 tx2 = f.x2;
            int32 ty2 = f.y2;

            if ((f.f1 & 8) != 0)
            {
                tx1 =
                    f.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.bottom - f.y1) * Fix64V1.ONE,
                        (f.x2 - f.x1) * Fix64V1.ONE,
                        (f.y2 - f.y1) * Fix64V1.ONE
                    );

                ty1 = g.clippingData.clipBox.bottom;
            }

            if ((f.f1 & 2) != 0)
            {
                tx1 =
                    f.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.top - f.y1) * Fix64V1.ONE,
                        (f.x2 - f.x1) * Fix64V1.ONE,
                        (f.y2 - f.y1) * Fix64V1.ONE
                    );

                ty1 = g.clippingData.clipBox.top;
            }

            if ((f.f2 & 8) != 0)
            {
                tx2 =
                    f.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.bottom - f.y1) * Fix64V1.ONE,
                        (f.x2 - f.x1) * Fix64V1.ONE,
                        (f.y2 - f.y1) * Fix64V1.ONE
                    );

                ty2 = g.clippingData.clipBox.bottom;
            }

            if ((f.f2 & 2) != 0)
            {
                tx2 =
                    f.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.top - f.y1) * Fix64V1.ONE,
                        (f.x2 - f.x1) * Fix64V1.ONE,
                        (f.y2 - f.y1) * Fix64V1.ONE
                    );

                ty2 = g.clippingData.clipBox.top;
            }

            CellRasterizer.line(CellRasterizer.Line(tx1, ty1, tx2, ty2), g.cellData, g.ss);
        }
    }

    function clippingFlags(
        int32 x,
        int32 y,
        RectangleInt memory clipBox
    ) private pure returns (int32) {
        return
            (x > clipBox.right ? int32(1) : int32(0)) |
            (y > clipBox.top ? int32(1) << 1 : int32(0)) |
            (x < clipBox.left ? int32(1) << 2 : int32(0)) |
            (y < clipBox.bottom ? int32(1) << 3 : int32(0));
    }

    function clippingFlagsY(int32 y, RectangleInt memory clipBox)
        private
        pure
        returns (int32)
    {
        return
            ((y > clipBox.top ? int32(1) : int32(0)) << 1) |
            ((y < clipBox.bottom ? int32(1) : int32(0)) << 3);
    }

    function mulDiv(
        int64 a,
        int64 b,
        int64 c
    ) private pure returns (int32) {
        int64 div = Fix64V1.div(b, c);
        int64 muldiv = Fix64V1.mul(a, div);
        return (int32)(Fix64V1.round(muldiv) / Fix64V1.ONE);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./_Structs.sol";
import "./Fix64V1.sol";

struct PixelClipping {
    Vector2[] area;
    int32 x;
    int32 y;
}

library PixelClippingMethods {
    function isPointInPolygon(
        PixelClipping memory self,
        int32 px,
        int32 py
    ) internal pure returns (bool) {
        if (self.area.length < 3) {
            return false;
        }

        Vector2 memory oldPoint = self.area[self.area.length - 1];

        bool inside = false;

        for (uint256 i = 0; i < self.area.length; i++) {
            Vector2 memory newPoint = self.area[i];

            Vector2 memory p2;
            Vector2 memory p1;

            if (newPoint.x > oldPoint.x) {
                p1 = oldPoint;
                p2 = newPoint;
            } else {
                p1 = newPoint;
                p2 = oldPoint;
            }

            int64 pxF = px * Fix64V1.ONE;
            int64 pyF = py * Fix64V1.ONE;

            int64 t1 = Fix64V1.sub(pyF, p1.y);
            int64 t2 = Fix64V1.sub(p2.x, p1.x);
            int64 t3 = Fix64V1.sub(p2.y, p1.y);
            int64 t4 = Fix64V1.sub(pxF, p1.x);

            if (
                newPoint.x < pxF == pxF <= oldPoint.x &&
                Fix64V1.mul(t1, t2) < Fix64V1.mul(t3, t4)
            ) inside = !inside;

            oldPoint = newPoint;
        }

        return inside;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";

library ColorMath {
    function toColor(
        uint8 a,
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint32) {
        uint32 c;
        c |= uint32(a) << 24;
        c |= uint32(r) << 16;
        c |= uint32(g) << 8;
        c |= uint32(b) << 0;
        return c & 0xffffffff;
    }

    function lerp(
        uint32 s,
        uint32 t,
        int64 k
    ) internal pure returns (uint32) {
        int64 bk = Fix64V1.sub(Fix64V1.ONE, k);

        int64 a = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 24))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 24))) * Fix64V1.ONE, k)
        );
        int64 r = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 16))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 16))) * Fix64V1.ONE, k)
        );
        int64 g = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 8))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 8))) * Fix64V1.ONE, k)
        );
        int64 b = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 0))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 0))) * Fix64V1.ONE, k)
        );

        int32 ra = (int32(a / Fix64V1.ONE) << 24);
        int32 rr = (int32(r / Fix64V1.ONE) << 16);
        int32 rg = (int32(g / Fix64V1.ONE) << 8);
        int32 rb = (int32(b / Fix64V1.ONE));

        int32 x = ra | rr | rg | rb;
        return uint32(x) & 0xffffffff;
    }

    function tint(uint32 targetColor, uint32 tintColor)
        internal
        pure
        returns (uint32 newColor)
    {
        uint8 a = (uint8)(targetColor >> 24);
        uint8 r = (uint8)(targetColor >> 16);
        uint8 g = (uint8)(targetColor >> 8);
        uint8 b = (uint8)(targetColor >> 0);

        if (a != 0 && r == 0 && g == 0 && b == 0) {
            return targetColor;
        }

        uint8 tr = (uint8)(tintColor >> 16);
        uint8 tg = (uint8)(tintColor >> 8);
        uint8 tb = (uint8)(tintColor >> 0);

        uint32 tinted = toColor(a, tr, tg, tb);
        return tinted;
    }
}

contract TestColorMath {
    function toColor(
        uint8 a,
        uint8 r,
        uint8 g,
        uint8 b
    ) external pure returns (uint32) {
        return ColorMath.toColor(a, r, g, b);
    }

    function lerp(
        uint32 s,
        uint32 t,
        int64 k
    ) external pure returns (uint32) {
        return ColorMath.lerp(s, t, k);
    }

    function tint(uint32 targetColor, uint32 tintColor)
        external
        pure
        returns (uint32 newColor)
    {
        return ColorMath.tint(targetColor, tintColor);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./_Structs.sol"; 
import "./Matrix.sol";

library ApplyTransform {
    function applyTransform(
        VertexData[] memory vertices,
        Matrix memory transform
    ) external pure returns (VertexData[] memory) {
        VertexData[] memory results = new VertexData[](vertices.length);
        for (uint32 i = 0; i < vertices.length; i++) {
            VertexData memory vertexData = vertices[i];
            VertexData memory transformedVertex = vertexData;

            if (
                transformedVertex.command != Command.Stop &&
                transformedVertex.command != Command.EndPoly
            ) {
                Vector2 memory position = transformedVertex.position;

                (int64 x, int64 y) = MatrixMethods.transform(
                    transform,
                    position.x,
                    position.y
                );
                position.x = x;
                position.y = y;

                transformedVertex.position = position;
            }

            results[i] = transformedVertex;
        }
        return results;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./SubpixelScale.sol";
import "./ScanlineData.sol";
import "./ClippingData.sol";
import "./CellData.sol";
import "./Graphics2D.sol";
import "./CellRasterizer.sol";
import "./ColorMath.sol";
import "./PixelClipping.sol";

library ScanlineRasterizer {
    function renderSolid(
        Graphics2D memory g,
        uint32 color,
        bool blend
    ) external pure returns (Graphics2D memory) {       
        
        if (rewindScanlines(g)) {
            resetScanline(g.cellData.minX, g.cellData.maxX, g.scanlineData);
            while (sweepScanline(g)) {

                int32 y = g.scanlineData.y;
                int32 spanCount = g.scanlineData.spanIndex;
                ScanlineSpan memory scanlineSpan = begin(g.scanlineData);
                
                uint8[] memory covers = g.scanlineData.covers;
                for (;;) {
                    int32 x = scanlineSpan.x;
                    if (scanlineSpan.length > 0) {
                        blendSolidHorizontalSpan(
                            g,
                            BlendSolidHorizontalSpan(
                                x,
                                y,
                                scanlineSpan.length,
                                color,
                                covers,
                                scanlineSpan.coverIndex,
                                blend
                            )
                        );
                    } else {                       

                        int32 x2 = x - scanlineSpan.length - 1;
                        blendHorizontalLine(
                            g,
                            BlendHorizontalLine(
                                x,
                                y,
                                x2,
                                color,
                                covers[uint32(scanlineSpan.coverIndex)],
                                blend
                            )
                        );
                    }

                    if (--spanCount == 0) break;
                    scanlineSpan = getNextScanlineSpan(g.scanlineData);                    
                }
            }
        }
        
        return g;
    }

    function sweepScanline(Graphics2D memory g) private pure returns (bool) {
        for (;;) {
            if (g.scanlineData.scanY > g.cellData.maxY) return false;

            resetSpans(g.scanlineData);
            int32 cellCount = g
                .cellData
                .sortedY[uint32(g.scanlineData.scanY - g.cellData.minY)]
                .count;

            (Cell[] memory cells, int32 offset) = scanlineCells(
                g.scanlineData.scanY,
                g.cellData
            );
            int32 cover = 0;

            while (cellCount != 0) {
                Cell memory current = cells[uint32(offset)];
                int32 x = current.x;
                int32 area = current.area;
                int32 alpha;

                cover += current.cover;

                while (--cellCount != 0) {
                    offset++;
                    current = cells[uint32(offset)];
                    if (current.x != x) break;

                    area += current.area;
                    cover += current.cover;
                }

                if (area != 0) {
                    alpha = calculateAlpha(
                        g,
                        (cover << (g.ss.value + 1)) - area
                    );
                    if (alpha != 0) {
                        addCell(g.scanlineData, x, alpha);
                    }
                    x++;
                }

                if (cellCount != 0 && current.x > x) {
                    alpha = calculateAlpha(g, cover << (g.ss.value + 1));
                    if (alpha != 0) {
                        addSpan(g.scanlineData, x, current.x - x, alpha);
                    }
                }
            }

            if (g.scanlineData.spanIndex != 0) break;
            ++g.scanlineData.scanY;
        }

        g.scanlineData.y = g.scanlineData.scanY;
        ++g.scanlineData.scanY;
        return true;
    }

    function calculateAlpha(Graphics2D memory g, int32 area)
        private
        pure
        returns (int32)
    {
        int32 cover = area >> (g.ss.value * 2 + 1 - g.aa.value);
        if (cover < 0) cover = -cover;
        if (cover > int32(g.aa.mask)) cover = int32(g.aa.mask);
        return g.scanlineData.gamma[uint32(cover)];
    }

    function addSpan(
        ScanlineData memory scanlineData,
        int32 x,
        int32 len,
        int32 cover
    ) private pure {
        if (
            x == scanlineData.lastX + 1 &&
            scanlineData.spans[uint32(scanlineData.spanIndex)].length < 0 &&
            cover ==
            scanlineData.spans[uint32(scanlineData.spanIndex)].coverIndex
        ) {
            scanlineData.spans[uint32(scanlineData.spanIndex)].length -= int16(
                len
            );
        } else {
            scanlineData.covers[uint32(scanlineData.coverIndex)] = uint8(
                uint32(cover)
            );
            scanlineData.spanIndex++;
            scanlineData
                .spans[uint32(scanlineData.spanIndex)]
                .coverIndex = scanlineData.coverIndex++;
            scanlineData.spans[uint32(scanlineData.spanIndex)].x = int16(x);
            scanlineData.spans[uint32(scanlineData.spanIndex)].length = int16(
                -len
            );
        }

        scanlineData.lastX = x + len - 1;
    }

    function addCell(
        ScanlineData memory scanlineData,
        int32 x,
        int32 cover
    ) private pure {
        scanlineData.covers[uint32(scanlineData.coverIndex)] = uint8(
            uint32(cover)
        );
        if (
            x == scanlineData.lastX + 1 &&
            scanlineData.spans[uint32(scanlineData.spanIndex)].length > 0
        ) {
            scanlineData.spans[uint32(scanlineData.spanIndex)].length++;
        } else {
            scanlineData.spanIndex++;
            scanlineData
                .spans[uint32(scanlineData.spanIndex)]
                .coverIndex = scanlineData.coverIndex;
            scanlineData.spans[uint32(scanlineData.spanIndex)].x = int16(x);
            scanlineData.spans[uint32(scanlineData.spanIndex)].length = 1;
        }

        scanlineData.lastX = x;
        scanlineData.coverIndex++;
    }

    function resetSpans(ScanlineData memory scanlineData) private pure {
        scanlineData.lastX = 0x7FFFFFF0;
        scanlineData.coverIndex = 0;
        scanlineData.spanIndex = 0;
        scanlineData.spans[uint32(scanlineData.spanIndex)].length = 0;
    }

    function begin(ScanlineData memory scanlineData)
        private
        pure
        returns (ScanlineSpan memory)
    {
        scanlineData.current = 1;
        return getNextScanlineSpan(scanlineData);
    }

    function resetScanline(
        int32 minX,
        int32 maxX,
        ScanlineData memory scanlineData
    ) private pure {
        int32 maxLength = maxX - minX + 3;
        if (maxLength > int256(scanlineData.spans.length)) {
            scanlineData.spans = new ScanlineSpan[](uint32(maxLength));
            scanlineData.covers = new uint8[](uint32(maxLength));
        }
        scanlineData.lastX = 0x7FFFFFF0;
        scanlineData.coverIndex = 0;
        scanlineData.spanIndex = 0;
        scanlineData.spans[uint32(scanlineData.spanIndex)].length = 0;
    }

    function getNextScanlineSpan(ScanlineData memory scanlineData)
        private
        pure
        returns (ScanlineSpan memory)
    {
        scanlineData.current++;
        return scanlineData.spans[uint32(scanlineData.current - 1)];
    }

    function scanlineCells(int32 y, CellData memory cellData)
        private
        pure
        returns (Cell[] memory cells, int32 offset)
    {
        cells = cellData.sortedCells;
        offset = cellData.sortedY[uint32(y - cellData.minY)].start;
    }

    function rewindScanlines(Graphics2D memory g) private pure returns (bool) {
        Graphics2DMethods.closePolygon(g);
        CellRasterizer.sortCells(g.cellData);
        if (g.cellData.used == 0) return false;
        g.scanlineData.scanY = g.cellData.minY;
        return true;
    }

    struct BlendSolidHorizontalSpan {
        int32 x;
        int32 y;
        int32 len;
        uint32 sourceColor;
        uint8[] covers;
        int32 coversIndex;
        bool blend;
    }

    function blendSolidHorizontalSpan(
        Graphics2D memory g,
        BlendSolidHorizontalSpan memory f
    ) private pure {

        int32 colorAlpha = (int32)(f.sourceColor >> 24);

        if (colorAlpha != 0) {
            unchecked {
                int32 bufferOffset = Graphics2DMethods.getBufferOffsetXy(
                    g,
                    f.x,
                    f.y
                );
                if (bufferOffset == -1) return;

                int32 i = 0;
                do {
                    int32 alpha = !f.blend ? colorAlpha : (colorAlpha * int32(uint32(f.covers[uint32(f.coversIndex)] + 1))) >> 8;

                    if (alpha == 255)
                        Graphics2DMethods.copyPixels(
                            g.buffer,
                            bufferOffset,
                            f.sourceColor,
                            1,
                            g.clippingData.clipPoly.length == 0
                                ? PixelClipping(new Vector2[](0), 0, 0)
                                : PixelClipping(
                                    g.clippingData.clipPoly,
                                    f.x + i,
                                    f.y
                                )
                        );
                    else {

                        uint32 targetColor = ColorMath.toColor(uint8(uint32(alpha)), 
                            uint8(f.sourceColor >> 16), 
                            uint8(f.sourceColor >> 8), 
                            uint8(f.sourceColor >> 0));

                        Graphics2DMethods.blendPixel(
                            g.buffer,
                            bufferOffset,
                            targetColor,
                            g.clippingData.clipPoly.length == 0
                                ? PixelClipping(new Vector2[](0), 0, 0)
                                : PixelClipping(
                                    g.clippingData.clipPoly,
                                    f.x + i,
                                    f.y
                                )
                        );
                    }

                    bufferOffset += 4;
                    f.coversIndex++;
                    i++;
                } while (--f.len != 0);
            }
        }
    }

    struct BlendHorizontalLine {
        int32 x1;
        int32 y;
        int32 x2;
        uint32 sourceColor;
        uint8 cover;
        bool blend;
    }

    function blendHorizontalLine(
        Graphics2D memory g,
        BlendHorizontalLine memory f
    ) private pure {
        int32 colorAlpha = (int32)(f.sourceColor >> 24);
        if (colorAlpha != 0) {

            int32 len = f.x2 - f.x1 + 1;
            int32 bufferOffset = Graphics2DMethods.getBufferOffsetXy(g, f.x1, f.y);            
            int32 alpha = !f.blend ? colorAlpha : (colorAlpha * int32(uint32(f.cover)) + 1) >> 8;

            if (alpha == 255) {
                Graphics2DMethods.copyPixels(
                    g.buffer,
                    bufferOffset,
                    f.sourceColor,
                    len,
                    g.clippingData.clipPoly.length == 0
                        ? PixelClipping(new Vector2[](0), 0, 0)
                        : PixelClipping(g.clippingData.clipPoly, f.x1, f.y)
                );
            } else {
                int32 i = 0;
                
                uint32 targetColor = ColorMath.toColor(uint8(uint32(alpha)), 
                uint8(f.sourceColor >> 16), 
                uint8(f.sourceColor >> 8), 
                uint8(f.sourceColor >> 0));

                do {
                    Graphics2DMethods.blendPixel(
                        g.buffer,
                        bufferOffset,
                        targetColor,
                        g.clippingData.clipPoly.length == 0
                            ? PixelClipping(new Vector2[](0), 0, 0)
                            : PixelClipping(
                                g.clippingData.clipPoly,
                                f.x1 + i,
                                f.y
                            )
                    );

                    bufferOffset += 4;
                    i++;
                } while (--len != 0);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./Trig256.sol";

library MathUtils {
    int32 public constant RecursionLimit = 32;
    int64 public constant AngleTolerance = 42949672; /* 0.01 */
    int64 public constant Epsilon = 4; /* 0.000000001 */

    function calcSquareDistance(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2
    ) internal pure returns (int64) {
        int64 dx = Fix64V1.sub(x2, x1);
        int64 dy = Fix64V1.sub(y2, y1);
        return Fix64V1.add(Fix64V1.mul(dx, dx), Fix64V1.mul(dy, dy));
    }

    function calcDistance(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2
    ) internal pure returns (int64) {
        int64 dx = Fix64V1.sub(x2, x1);
        int64 dy = Fix64V1.sub(y2, y1);
        int64 distance = Trig256.sqrt(
            Fix64V1.add(Fix64V1.mul(dx, dx), Fix64V1.mul(dy, dy))
        );
        return distance;
    }

    function crossProduct(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2,
        int64 x,
        int64 y
    ) internal pure returns (int64) {
        return
            Fix64V1.sub(
                Fix64V1.mul(Fix64V1.sub(x, x2), Fix64V1.sub(y2, y1)),
                Fix64V1.mul(Fix64V1.sub(y, y2), Fix64V1.sub(x2, x1))
            );
    }

    struct CalcIntersection {
        int64 aX1;
        int64 aY1;
        int64 aX2;
        int64 aY2;
        int64 bX1;
        int64 bY1;
        int64 bX2;
        int64 bY2;
    }

    function calcIntersection(CalcIntersection memory f)
        internal
        pure
        returns (
            int64 x,
            int64 y,
            bool
        )
    {
        int64 num = Fix64V1.mul(
            Fix64V1.sub(f.aY1, f.bY1),
            Fix64V1.sub(f.bX2, f.bX1)
        ) - Fix64V1.mul(Fix64V1.sub(f.aX1, f.bX1), Fix64V1.sub(f.bY2, f.bY1));
        int64 den = Fix64V1.mul(
            Fix64V1.sub(f.aX2, f.aX1),
            Fix64V1.sub(f.bY2, f.bY1)
        ) - Fix64V1.mul(Fix64V1.sub(f.aY2, f.aY1), Fix64V1.sub(f.bX2, f.bX1));

        if (Fix64V1.abs(den) < Epsilon) {
            x = 0;
            y = 0;
            return (x, y, false);
        }

        int64 r = Fix64V1.div(num, den);
        x = Fix64V1.add(f.aX1, Fix64V1.mul(r, Fix64V1.sub(f.aX2, f.aX1)));
        y = Fix64V1.add(f.aY1, Fix64V1.mul(r, Fix64V1.sub(f.aY2, f.aY1)));
        return (x, y, true);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

struct Cell {
    int32 x;
    int32 y;
    int32 cover;
    int32 area;
    int32 left;
    int32 right;
}

library CellMethods {
    function create() internal pure returns (Cell memory cell) {
        cell.x = 0x7FFFFFFF;
        cell.y = 0x7FFFFFFF;
        cell.cover = 0;
        cell.area = 0;
        cell.left = -1;
        cell.right = -1;
    }

    function set(Cell memory cell, Cell memory other) internal pure {
        cell.x = other.x;
        cell.y = other.y;
        cell.cover = other.cover;
        cell.area = other.area;
        cell.left = other.left;
        cell.right = other.right;
    }

    function style(Cell memory self, Cell memory other) internal pure {
        self.left = other.left;
        self.right = other.right;
    }

    function notEqual(
        Cell memory self,
        int32 ex,
        int32 ey,
        Cell memory other
    ) internal pure returns (bool) {
        unchecked {
            return
                ((ex - self.x) |
                    (ey - self.y) |
                    (self.left - other.left) |
                    (self.right - other.right)) != 0;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

struct CellBlock {
    uint32 shift;
    uint32 size;
    uint32 mask;
    uint32 limit;
}

library CellBlockMethods {
    function create(uint32 sampling)
        internal
        pure
        returns (CellBlock memory cb)
    {
        cb.shift = sampling;
        cb.size = uint32(1) << cb.shift;
        cb.mask = cb.size - 1;
        cb.limit = 1024 * cb.size;
        return cb;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./CellData.sol";
import "./SubpixelScale.sol";
import "./Graphics2D.sol";

library CellRasterizer {
    function resetCells(CellData memory cellData)
        internal
        pure
    {
        cellData.used = 0;
        cellData.style = CellMethods.create();
        cellData.current = CellMethods.create();
        cellData.sorted = false;

        cellData.minX = 0x7FFFFFFF;
        cellData.minY = 0x7FFFFFFF;
        cellData.maxX = -0x7FFFFFFF;
        cellData.maxY = -0x7FFFFFFF;
    }

    struct Line {
        int32 x1;
        int32 y1;
        int32 x2;
        int32 y2;
    }

    struct LineArgs {
        int32 dx;
        int32 dy;
        int32 ex1;
        int32 ex2;
        int32 ey1;
        int32 ey2;
        int32 fy1;
        int32 fy2;
        int32 delta;
        int32 first;
        int32 incr;
    }

    function line(Line memory f, CellData memory cellData, SubpixelScale memory ss) internal pure {
        LineArgs memory a;

        a.dx = f.x2 - f.x1;

        if (a.dx >= int32(ss.dxLimit) || a.dx <= -int32(ss.dxLimit)) {
            int32 cx = (f.x1 + f.x2) >> 1;
            int32 cy = (f.y1 + f.y2) >> 1;
            line(Line(f.x1, f.y1, cx, cy), cellData, ss);
            line(Line(cx, cy, f.x2, f.y2), cellData, ss);
        }

        a.dy = f.y2 - f.y1;
        a.ex1 = f.x1 >> ss.value;
        a.ex2 = f.x2 >> ss.value;
        a.ey1 = f.y1 >> ss.value;
        a.ey2 = f.y2 >> ss.value;
        a.fy1 = f.y1 & int32(ss.mask);
        a.fy2 = f.y2 & int32(ss.mask);

        {
            if (a.ex1 < cellData.minX) cellData.minX = a.ex1;
            if (a.ex1 > cellData.maxX) cellData.maxX = a.ex1;
            if (a.ey1 < cellData.minY) cellData.minY = a.ey1;
            if (a.ey1 > cellData.maxY) cellData.maxY = a.ey1;
            if (a.ex2 < cellData.minX) cellData.minX = a.ex2;
            if (a.ex2 > cellData.maxX) cellData.maxX = a.ex2;
            if (a.ey2 < cellData.minY) cellData.minY = a.ey2;
            if (a.ey2 > cellData.maxY) cellData.maxY = a.ey2;

            setCurrentCell(a.ex1, a.ey1, cellData);

            if (a.ey1 == a.ey2) {
                renderHorizontalLine(                    
                    RenderHorizontalLine(a.ey1, f.x1, a.fy1, f.x2, a.fy2),
                    cellData, ss
                );
                return;
            }
        }

        a.incr = 1;

        if (a.dx == 0) {
            int32 ex = f.x1 >> ss.value;
            int32 twoFx = (f.x1 - (ex << ss.value)) << 1;

            a.first = int32(ss.scale);
            if (a.dy < 0) {
                a.first = 0;
                a.incr = -1;
            }

            a.delta = a.first - a.fy1;
            cellData.current.cover += a.delta;
            cellData.current.area += twoFx * a.delta;

            a.ey1 += a.incr;
            setCurrentCell(ex, a.ey1, cellData);

            a.delta = a.first + a.first - int32(ss.scale);
            int32 area = twoFx * a.delta;
            while (a.ey1 != a.ey2) {
                cellData.current.cover = a.delta;
                cellData.current.area = area;
                a.ey1 += a.incr;
                setCurrentCell(ex, a.ey1, cellData);
            }

            a.delta = a.fy2 - int32(ss.scale) + a.first;
            cellData.current.cover += a.delta;
            cellData.current.area += twoFx * a.delta;
            return;
        }

        int32 p = (int32(ss.scale) - a.fy1) * a.dx;
        a.first = int32(ss.scale);

        if (a.dy < 0) {
            p = a.fy1 * a.dx;
            a.first = 0;
            a.incr = -1;
            a.dy = -a.dy;
        }

        a.delta = p / a.dy;
        int32 mod = p % a.dy;

        if (mod < 0) {
            a.delta--;
            mod += a.dy;
        }

        int32 xFrom = f.x1 + a.delta;
        renderHorizontalLine(            
            RenderHorizontalLine(a.ey1, f.x1, a.fy1, xFrom, a.first), cellData, ss
        );

        a.ey1 += a.incr;
        setCurrentCell(xFrom >> ss.value, a.ey1, cellData);

        if (a.ey1 != a.ey2) {
            p = int32(ss.scale) * a.dx;
            int32 lift = p / a.dy;
            int32 rem = p % a.dy;

            if (rem < 0) {
                lift--;
                rem += a.dy;
            }

            mod -= a.dy;

            while (a.ey1 != a.ey2) {
                a.delta = lift;
                mod += rem;
                if (mod >= 0) {
                    mod -= a.dy;
                    a.delta++;
                }

                int32 xTo = xFrom + a.delta;
                renderHorizontalLine(
                    RenderHorizontalLine(
                        a.ey1,
                        xFrom,
                        int32(ss.scale) - a.first,
                        xTo,
                        a.first
                    ), cellData, ss
                );
                xFrom = xTo;

                a.ey1 += a.incr;
                setCurrentCell(xFrom >> ss.value, a.ey1, cellData);
            }
        }

        renderHorizontalLine(            
            RenderHorizontalLine(
                a.ey1,
                xFrom,
                int32(ss.scale) - a.first,
                f.x2,
                a.fy2
            ), cellData, ss
        );
    }

    function sortCells(CellData memory cellData) internal pure {
        if (cellData.sorted) return;

        addCurrentCell(cellData);
        cellData.current.x = 0x7FFFFFFF;
        cellData.current.y = 0x7FFFFFFF;
        cellData.current.cover = 0;
        cellData.current.area = 0;

        if (cellData.used == 0) return;

        cellData.sortedCells = new Cell[](cellData.used);
        cellData.sortedY = new SortedY[](
            uint32(cellData.maxY - cellData.minY + 1)
        );

        Cell[] memory cells = cellData.cells;
        SortedY[] memory sortedYData = cellData.sortedY;
        Cell[] memory sortedCellsData = cellData.sortedCells;

        for (uint32 i = 0; i < cellData.used; i++) {
            int32 index = cells[i].y - cellData.minY;
            sortedYData[uint32(index)].start++;
        }

        int32 start = 0;
        uint32 sortedYSize = uint32(cellData.sortedY.length);
        for (uint32 i = 0; i < sortedYSize; i++) {
            int32 v = sortedYData[i].start;
            sortedYData[i].start = start;
            start += v;
        }

        for (uint32 i = 0; i < cellData.used; i++) {
            int32 index = cells[i].y - cellData.minY;
            int32 currentYStart = sortedYData[uint32(index)].start;
            int32 currentYCount = sortedYData[uint32(index)].count;
            sortedCellsData[uint32(currentYStart + currentYCount)] = cells[i];
            ++sortedYData[uint32(index)].count;
        }

        for (uint32 i = 0; i < sortedYSize; i++)
            if (sortedYData[i].count != 0)
                sort(
                    sortedCellsData,
                    sortedYData[i].start,
                    sortedYData[i].start + sortedYData[i].count - 1
                );

        cellData.sorted = true;
    }

    struct RenderHorizontalLine {
        int32 ey;
        int32 x1;
        int32 y1;
        int32 x2;
        int32 y2;
    }

    struct RenderHorizontalLineArgs {
        int32 ex1;
        int32 ex2;
        int32 fx1;
        int32 fx2;
        int32 delta;
    }

    function renderHorizontalLine(        
        RenderHorizontalLine memory f,
        CellData memory cellData,
        SubpixelScale memory ss
    ) private pure {
        RenderHorizontalLineArgs memory a;

        a.ex1 = f.x1 >> ss.value;
        a.ex2 = f.x2 >> ss.value;
        a.fx1 = f.x1 & int32(ss.mask);
        a.fx2 = f.x2 & int32(ss.mask);
        a.delta = 0;

        if (f.y1 == f.y2) {
            setCurrentCell(a.ex2, f.ey, cellData);
            return;
        }

        if (a.ex1 == a.ex2) {
            a.delta = f.y2 - f.y1;
            cellData.current.cover += a.delta;
            cellData.current.area += (a.fx1 + a.fx2) * a.delta;
            return;
        }

        int32 p = (int32(ss.scale) - a.fx1) * (f.y2 - f.y1);
        int32 first = int32(ss.scale);
        int32 incr = 1;
        int32 dx = f.x2 - f.x1;

        if (dx < 0) {
            p = a.fx1 * (f.y2 - f.y1);
            first = 0;
            incr = -1;
            dx = -dx;
        }

        a.delta = p / dx;
        int32 mod = p % dx;

        if (mod < 0) {
            a.delta--;
            mod += dx;
        }

        cellData.current.cover += a.delta;
        cellData.current.area += (a.fx1 + first) * a.delta;

        a.ex1 += incr;
        setCurrentCell(a.ex1, f.ey, cellData);
        f.y1 += a.delta;

        if (a.ex1 != a.ex2) {
            p = int32(ss.scale) * (f.y2 - f.y1 + a.delta);
            int32 lift = p / dx;
            int32 rem = p % dx;

            if (rem < 0) {
                lift--;
                rem += dx;
            }

            mod -= dx;

            while (a.ex1 != a.ex2) {
                a.delta = lift;
                mod += rem;
                if (mod >= 0) {
                    mod -= dx;
                    a.delta++;
                }

                cellData.current.cover += a.delta;
                cellData.current.area += int32(ss.scale) * a.delta;
                f.y1 += a.delta;
                a.ex1 += incr;
                setCurrentCell(a.ex1, f.ey, cellData);
            }
        }

        a.delta = f.y2 - f.y1;
        cellData.current.cover += a.delta;
        cellData.current.area +=
            (a.fx2 + int32(ss.scale) - first) *
            a.delta;
    }

    function setCurrentCell(
        int32 x,
        int32 y,
        CellData memory cellData
    ) private pure {
        if (CellMethods.notEqual(cellData.current, x, y, cellData.style)) {
            addCurrentCell(cellData);
            CellMethods.style(cellData.current, cellData.style);
            cellData.current.x = x;
            cellData.current.y = y;
            cellData.current.cover = 0;
            cellData.current.area = 0;
        }
    }

    function addCurrentCell(CellData memory cellData) private pure {
        if ((cellData.current.area | cellData.current.cover) != 0) {
            if (cellData.used >= cellData.cb.limit) return;
            CellMethods.set(cellData.cells[cellData.used], cellData.current);
            cellData.used++;
        }
    }

    function sort(
        Cell[] memory cells,
        int32 start,
        int32 stop
    ) private pure {
        while (true) {
            if (stop == start) return;

            int32 pivot = getPivotPoint(cells, start, stop);
            if (pivot > start) sort(cells, start, pivot - 1);

            if (pivot < stop) {
                start = pivot + 1;
                continue;
            }

            break;
        }
    }

    function getPivotPoint(
        Cell[] memory cells,
        int32 start,
        int32 stop
    ) private pure returns (int32) {
        int32 m = start + 1;
        int32 n = stop;
        while (m < stop && cells[uint32(start)].x >= cells[uint32(m)].x) m++;

        while (n > start && cells[uint32(start)].x <= cells[uint32(n)].x) n--;
        while (m < n) {
            (cells[uint32(m)], cells[uint32(n)]) = (
                cells[uint32(n)],
                cells[uint32(m)]
            );
            while (m < stop && cells[uint32(start)].x >= cells[uint32(m)].x)
                m++;
            while (n > start && cells[uint32(start)].x <= cells[uint32(n)].x)
                n--;
        }

        if (start != n) {
            (cells[uint32(n)], cells[uint32(start)]) = (
                cells[uint32(start)],
                cells[uint32(n)]
            );
        }

        return n;
    }
}