// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/*
30Web3

ERC721, Enumerable, Ownable, Adminlist

Core is ERC721 library from Solmate by @transmissions11, modified to support
Open Zeppelin Enumerable extension and hooks. Lilownable by @m1guelpf. Adminlist
based on a branch of Open Zeppelin ownership branch from 2018.

ERC721 Solmate: https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol
OZ Enumerable:  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.2/contracts/token/ERC721/extensions/ERC721Enumerable.sol
Lilownable:     https://github.com/m1guelpf/erc721-drop/blob/main/src/LilOwnable.sol
Adminlist:      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/025c9bdcde412e65a307e4985151e7c023fd3870/contracts/ownership/Whitelist.sol

@author kethic, xavier, larkef
*/

/// ----------------------------------------------------------------------------
/// Imports
/// ----------------------------------------------------------------------------
import "./ERC721_Solmate_Hooked.sol";
import "./LilOwnable.sol";
import "./Adminlist.sol";

// Thank you tangert
// https://gist.github.com/tangert/1eceaf04f2877d84fb0e10681b39d7e3#file-renderer-sol
import "./Renderer.sol";

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// ----------------------------------------------------------------------------
/// Enums and Structs
/// ----------------------------------------------------------------------------

/// ----------------------------------------------------------------------------
/// Errors
/// ----------------------------------------------------------------------------
error InvalidToken();
error IndexOutOfBounds();
error TransferFailed();
error NoReentrancy();

contract NFT30Web3 is ERC721, LilOwnable, Adminlist, Renderer {

    /// ------------------------------------------------------------------------
    /// Events
    /// ------------------------------------------------------------------------

    /// ------------------------------------------------------------------------
    /// Variables
    /// ------------------------------------------------------------------------

    uint256 private currentToken;
    string public cohort;
    mapping(uint256 => string) idToCohort;

    uint8 private _mutex = 1;

    /// ------------------------------------------------------------------------
    /// Modifiers
    /// ------------------------------------------------------------------------

    modifier isValidToken(uint256 id) {
        if(ownerOf[id] == address(0)) revert InvalidToken();
        _;
    }

    modifier mutex() {
        if(_mutex == 2) revert NoReentrancy();

        _mutex = 2;
        _;
        _mutex = 1;
    }
    
    /// ------------------------------------------------------------------------
    /// Functions
    /// ------------------------------------------------------------------------

    constructor(
        address[] memory _adminlist,
        string memory _cohort
    ) ERC721 (
        "30Web3 Graduates",
        "30Web3"
    ) {

        // Deployer has Admin Rights
        _setupAdmin(msg.sender);

        // Add the other Admins
        uint16 length = uint16(_adminlist.length);
        for(uint16 i=0; i < length; i = uncheckedInc(i))
        {
            _setupAdmin(_adminlist[i]);
        }

        setCohort(_cohort);
    }

    function setCohort(
        string memory _cohort
    )
        public 
        onlyAdmin
    {
        cohort = _cohort;
    }

    function mint(
        address _target
    )
        external
        payable 
        onlyAdmin
        mutex
    {
        _mint(address(_target), currentToken);
        idToCohort[currentToken] = cohort;
        currentToken++;
    }

    function tokenURI(
        uint256 id
    )
        public
        view
        override
        isValidToken(id)
        returns (string memory) 
    {
        string memory svgString = _render(id, idToCohort[id]);
        return buildSvg("30Web3", "Congratulations on your successful completion of 30Web3!", svgString);
    }

    function contractURI()
        public
        pure 
        returns (string memory) 
    {
        return "data:application/json;base64,eyJuYW1lIjoiMzBXZWIzIEdyYWR1YXRlcyIsImRlc2NyaXB0aW9uIjoiMzAgZGF5cyBvZiBXZWIzIGlzIGFuIG9wcG9ydHVuaXR5IHRvIHdvcmsgd2l0aCB5b3VyIHBlZXJzLCBzaGlwIGEgcHJvamVjdCwgYW5kIGdhaW4gaGFuZHMtb24gV2ViMyBleHBlcmllbmNlIGluIHNtYWxsLCBjb2xsYWJvcmF0aXZlLCBmb2N1c2VkIGNvaG9ydHMuIFRoZXNlIHRva2VucyBjb21tZW1vcmF0ZSB0aGUgZ3JhZHVhdGVzIGZyb20gZWFjaCBjb2hvcnQuIiwiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTlRSd2VDSWdhR1ZwWjJoMFBTSTBNSEI0SWlCMmFXVjNRbTk0UFNJd0lEQWdNelkySURJMk5pSWdabWxzYkQwaWJtOXVaU0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Wld4c2FYQnpaU0JqZUQwaU1UTXlJaUJqZVQwaU1UTXpMalVpSUhKNFBTSXhNeklpSUhKNVBTSXhNekl1TlNJZ1ptbHNiRDBpSTBaR01EQTJSaUkrUEM5bGJHeHBjSE5sUGp4bklITjBlV3hsUFNKdGFYZ3RZbXhsYm1RdGJXOWtaVG9nWTI5c2IzSXRaRzlrWjJVN0lqNDhaV3hzYVhCelpTQmplRDBpTWpNMElpQmplVDBpTVRNeUxqVWlJSEo0UFNJeE16SWlJSEo1UFNJeE16SXVOU0lnWm1sc2JEMGlkMmhwZEdVaVBqd3ZaV3hzYVhCelpUNDhMMmMrUEhCaGRHZ2dabWxzYkMxeWRXeGxQU0psZG1WdWIyUmtJaUJqYkdsd0xYSjFiR1U5SW1WMlpXNXZaR1FpSUdROUlrMHhPREV1T0RFeUlERXdMamMxT0RkRE1qTXdMakF5TWlBek1DNDBPVEl5SURJMk5DQTNPQzR3TVRNeElESTJOQ0F4TXpNdU5VTXlOalFnTVRnNExqQTNNU0F5TXpFdU1UTTFJREl6TkM0NU16Y2dNVGcwTGpFNE9DQXlOVFV1TWpReFF6RXpOUzQ1TnpnZ01qTTFMalV3T0NBeE1ESWdNVGczTGprNE55QXhNRElnTVRNeUxqVkRNVEF5SURjM0xqa3lPVElnTVRNMExqZzJOU0F6TVM0d05qTTFJREU0TVM0NE1USWdNVEF1TnpVNE4xb2lJR1pwYkd3OUlpTkdSakF3UmtZaVBqd3ZjR0YwYUQ0OFkybHlZMnhsSUdONFBTSXhPRE1pSUdONVBTSXhNeklpSUhJOUlqZ3hJaUJtYVd4c1BTSWpPRFF6T1VWRUlqNDhMMk5wY21Oc1pUNDhjR0YwYUNCa1BTSk5NVFF3TGpneE5pQXhORE11T0RnNFF6RTBNQzQ0TVRZZ01UUTNMalF5T1NBeE16a3VPVFl6SURFMU1DNHdNVEVnTVRNNExqSTFOaUF4TlRFdU5qTXlRekV6Tmk0MU5Ea2dNVFV6TGpJeE1TQXhNek11TnpjMklERTFOQ0F4TWprdU9UTTJJREUxTkVneE1qRXVOelEwVmpFME9TNHlTREV6TUM0MU1USkRNVE15TGpFek15QXhORGt1TWlBeE16TXVNekk0SURFME9DNDRNemNnTVRNMExqQTVOaUF4TkRndU1URXlRekV6TkM0NE5qUWdNVFEzTGpNME5DQXhNelV1TWpRNElERTBOaTR4TkRrZ01UTTFMakkwT0NBeE5EUXVOVEk0VmpFek55NDVNelpETVRNMUxqSTBPQ0F4TXpZdU5USTRJREV6TkM0NE1qRWdNVE0xTGpReE9TQXhNek11T1RZNElERXpOQzQyTURoRE1UTXpMakV4TlNBeE16TXVOelUxSURFek1TNDVPRFFnTVRNekxqTXlPQ0F4TXpBdU5UYzJJREV6TXk0ek1qaElNVEl6TGpjeU9GWXhNamd1TlRJNFNERXlPUzQ1TXpaRE1UTXhMakkxT1NBeE1qZ3VOVEk0SURFek1pNHpOamdnTVRJNExqRXdNU0F4TXpNdU1qWTBJREV5Tnk0eU5EaERNVE0wTGpFMklERXlOaTR6T1RVZ01UTTBMall3T0NBeE1qVXVNalkwSURFek5DNDJNRGdnTVRJekxqZzFObFl4TVRndU5qQTRRekV6TkM0Mk1EZ2dNVEUyTGprNE55QXhNelF1TWpJMElERXhOUzQ0TVRNZ01UTXpMalExTmlBeE1UVXVNRGc0UXpFek1pNDNNekVnTVRFMExqTTJNeUF4TXpFdU5UVTNJREV4TkNBeE1qa3VPVE0ySURFeE5FZ3hNakV1TnpRMFZqRXdPUzR5U0RFeU9TNHhOamhETVRNeUxqYzVOU0F4TURrdU1pQXhNelV1TlRJMUlERXhNQzR3TVRFZ01UTTNMak0ySURFeE1TNDJNekpETVRNNUxqSXpOeUF4TVRNdU1qRXhJREUwTUM0eE56WWdNVEUxTGpjeU9DQXhOREF1TVRjMklERXhPUzR4T0RSV01USXpMakl4TmtNeE5EQXVNVGMySURFeU5pNDFNREVnTVRNNUxqQXdNeUF4TWpndU9UYzJJREV6Tmk0Mk5UWWdNVE13TGpZMFF6RXpPUzQwTWprZ01UTXlMakUzTmlBeE5EQXVPREUySURFek5DNDRJREUwTUM0NE1UWWdNVE00TGpVeE1sWXhORE11T0RnNFdrMHhOemN1TWpNMUlERTBNeTR4TWtNeE56Y3VNak0xSURFME5pNDJOakVnTVRjMkxqSTFNeUF4TkRrdU16Y3hJREUzTkM0eU9URWdNVFV4TGpJME9FTXhOekl1TXpjeElERTFNeTR3T0RNZ01UWTVMamMyT0NBeE5UUWdNVFkyTGpRNE15QXhOVFJJTVRZMUxqSXdNME14TmpFdU9URTNJREUxTkNBeE5Ua3VNamt6SURFMU15NHdPRE1nTVRVM0xqTXpNU0F4TlRFdU1qUTRRekUxTlM0ME1URWdNVFE1TGpNM01TQXhOVFF1TkRVeElERTBOaTQyTmpFZ01UVTBMalExTVNBeE5ETXVNVEpXTVRJd0xqQTRRekUxTkM0ME5URWdNVEUyTGpRNU5pQXhOVFV1TkRFeElERXhNeTQzT0RjZ01UVTNMak16TVNBeE1URXVPVFV5UXpFMU9TNHlOVEVnTVRFd0xqRXhOeUF4TmpFdU9EYzFJREV3T1M0eUlERTJOUzR5TURNZ01UQTVMakpJTVRZMkxqUTRNME14TmprdU9ERXhJREV3T1M0eUlERTNNaTQwTXpVZ01URXdMakV4TnlBeE56UXVNelUxSURFeE1TNDVOVEpETVRjMkxqSTNOU0F4TVRNdU56ZzNJREUzTnk0eU16VWdNVEUyTGpRNU5pQXhOemN1TWpNMUlERXlNQzR3T0ZZeE5ETXVNVEphVFRFM01TNDNPVFVnTVRFNExqZzJORU14TnpFdU56azFJREV4Tnk0MU5ERWdNVGN4TGpJNE15QXhNVFl1TkRFeElERTNNQzR5TlRrZ01URTFMalEzTWtNeE5qa3VNamMzSURFeE5DNDBPVEVnTVRZNExqQXhPU0F4TVRRZ01UWTJMalE0TXlBeE1UUklNVFkxTGpJd00wTXhOak11TmpZM0lERXhOQ0F4TmpJdU16ZzNJREV4TkM0ME9URWdNVFl4TGpNMk15QXhNVFV1TkRjeVF6RTJNQzR6T0RFZ01URTJMalF4TVNBeE5Ua3VPRGt4SURFeE55NDFOREVnTVRVNUxqZzVNU0F4TVRndU9EWTBWakV6Tmk0eU1EaE1NVGN4TGpjNU5TQXhNVGd1T0RZMFdrMHhOVGt1T0RreElERTBOQzR6TXpaRE1UVTVMamc1TVNBeE5EVXVOalU1SURFMk1DNHpPREVnTVRRMkxqZ3hNU0F4TmpFdU16WXpJREUwTnk0M09USkRNVFl5TGpNNE55QXhORGd1TnpNeElERTJNeTQyTmpjZ01UUTVMaklnTVRZMUxqSXdNeUF4TkRrdU1rZ3hOall1TkRnelF6RTJPQzR3TVRrZ01UUTVMaklnTVRZNUxqSTNOeUF4TkRndU56TXhJREUzTUM0eU5Ua2dNVFEzTGpjNU1rTXhOekV1TWpneklERTBOaTQ0TVRFZ01UY3hMamM1TlNBeE5EVXVOalU1SURFM01TNDNPVFVnTVRRMExqTXpObFl4TWpjdU1EVTJUREUxT1M0NE9URWdNVFEwTGpNek5scE5NakF3TGpJM055QXhNelV1T0RJMFRERTVOaTR5TkRVZ01UVTBTREU0T0M0MU5qVk1NVGcyTGpNNE9TQXhNRGt1TWtneE9URXVNVEkxVERFNU15NHdORFVnTVRRNUxqSk1NVGs0TGpNMU55QXhNamd1TURoSU1qQXlMak15TlV3eU1EY3VOelkxSURFME9TNHlUREl3T1M0M05Ea2dNVEE1TGpKSU1qRTBMakUyTlV3eU1URXVPVGc1SURFMU5FZ3lNRE11T1RJMVRESXdNQzR5TnpjZ01UTTFMamd5TkZwTk1qUTBMalV3TkNBeE5ETXVPRGc0UXpJME5DNDFNRFFnTVRRM0xqUXlPU0F5TkRNdU5qVWdNVFV3TGpBeE1TQXlOREV1T1RRMElERTFNUzQyTXpKRE1qUXdMakl6TnlBeE5UTXVNakV4SURJek55NDBOalFnTVRVMElESXpNeTQyTWpRZ01UVTBTREl5TlM0ME16SldNVFE1TGpKSU1qTTBMakpETWpNMUxqZ3lNU0F4TkRrdU1pQXlNemN1TURFMklERTBPQzQ0TXpjZ01qTTNMamM0TkNBeE5EZ3VNVEV5UXpJek9DNDFOVElnTVRRM0xqTTBOQ0F5TXpndU9UTTJJREUwTmk0eE5Ea2dNak00TGprek5pQXhORFF1TlRJNFZqRXpOeTQ1TXpaRE1qTTRMamt6TmlBeE16WXVOVEk0SURJek9DNDFNRGtnTVRNMUxqUXhPU0F5TXpjdU5qVTJJREV6TkM0Mk1EaERNak0yTGpnd01pQXhNek11TnpVMUlESXpOUzQyTnpJZ01UTXpMak15T0NBeU16UXVNalkwSURFek15NHpNamhJTWpJM0xqUXhObFl4TWpndU5USTRTREl6TXk0Mk1qUkRNak0wTGprME5pQXhNamd1TlRJNElESXpOaTR3TlRZZ01USTRMakV3TVNBeU16WXVPVFV5SURFeU55NHlORGhETWpNM0xqZzBPQ0F4TWpZdU16azFJREl6T0M0eU9UWWdNVEkxTGpJMk5DQXlNemd1TWprMklERXlNeTQ0TlRaV01URTRMall3T0VNeU16Z3VNamsySURFeE5pNDVPRGNnTWpNM0xqa3hNaUF4TVRVdU9ERXpJREl6Tnk0eE5EUWdNVEUxTGpBNE9FTXlNell1TkRFNElERXhOQzR6TmpNZ01qTTFMakkwTlNBeE1UUWdNak16TGpZeU5DQXhNVFJJTWpJMUxqUXpNbFl4TURrdU1rZ3lNekl1T0RVMlF6SXpOaTQwT0RJZ01UQTVMaklnTWpNNUxqSXhNeUF4TVRBdU1ERXhJREkwTVM0d05EZ2dNVEV4TGpZek1rTXlOREl1T1RJMUlERXhNeTR5TVRFZ01qUXpMamcyTkNBeE1UVXVOekk0SURJME15NDROalFnTVRFNUxqRTRORll4TWpNdU1qRTJRekkwTXk0NE5qUWdNVEkyTGpVd01TQXlOREl1TmprZ01USTRMamszTmlBeU5EQXVNelEwSURFek1DNDJORU15TkRNdU1URTNJREV6TWk0eE56WWdNalEwTGpVd05DQXhNelF1T0NBeU5EUXVOVEEwSURFek9DNDFNVEpXTVRRekxqZzRPRm9pSUdacGJHdzlJbmRvYVhSbElqNDhMM0JoZEdnK1BDOXpkbWMrIiwiZXh0ZXJuYWxfbGluayI6Imh0dHBzOi8vdHdpdHRlci5jb20vd3NseXZoIiwiZmVlX3JlY2lwaWVudCI6IjB4NjNjYWI2OTE4OWRCYTJmMTU0NGEyNWM4QzE5YjQzMDlmNDE1YzhBQSIsInNlbGxlcl9mZWVfYmFzaXNfcG9pbnRzIjowfQ==";
    }

    function withdraw()
        public
        onlyAdmin
    {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(
        IERC20 token
    )
        public
        onlyAdmin 
    {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /// ------------------------------------------------------------------------
    /// ERC721Enumerable Variables
    /// ------------------------------------------------------------------------

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /// ------------------------------------------------------------------------
    /// ERC721Enumerable Functions
    /// ------------------------------------------------------------------------

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    )
        public
        view
        returns (uint256) 
    {
        if(index >= ERC721.balanceOf[owner]) revert IndexOutOfBounds();
        return _ownedTokens[owner][index];
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _allTokens.length;
    }

    function tokenByIndex(
        uint256 index
    )
        public
        view
        returns (uint256) 
    {
        if(index >= totalSupply()) revert IndexOutOfBounds();
        return _allTokens[index];
    }

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

    function _addTokenToOwnerEnumeration(
        address to,
        uint256 tokenId
    )
        private
    {
        uint256 length = ERC721.balanceOf[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(
        uint256 tokenId
    )
        private
    {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(
        address from, 
        uint256 tokenId
    )
        private 
    {
        uint256 lastTokenIndex = ERC721.balanceOf[from] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }


    /// ------------------------------------------------------------------------
    /// ERC165
    /// ------------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721, LilOwnable)
        returns (bool)
    {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
        interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
        interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
        interfaceId == 0x780e9d63;   // ERC165 Interface ID for ERC721Enumerable
    }

    /// ------------------------------------------------------------------------
    /// Utility Functions
    /// ------------------------------------------------------------------------

    //https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
    function toAsciiString(
        address x
    )   
        internal
        pure 
        returns (string memory) 
    {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function buildSvg(
        string memory nftName,
        string memory nftDescription,
        string memory svgString
    ) 
        public 
        pure 
        returns (string memory) 
    {
        string memory imgEncoded = Base64.encode(bytes(svgString));
        string memory imgURI = string(
            abi.encodePacked("data:image/svg+xml;base64,", imgEncoded)
        );
        string memory nftJson = string(
            abi.encodePacked(
                '{"name": "',
                nftName,
                '", "description": "',
                nftDescription,
                '", "image": "',
                imgURI,
                '"}'
            )
        );
        string memory nftEncoded = Base64.encode(bytes(nftJson));
        string memory finalURI = string(
            abi.encodePacked("data:application/json;base64,", nftEncoded)
        );
        return finalURI;
    }

    function char(
        bytes1 b
    )
        internal
        pure 
        returns (bytes1 c)
    {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    // https://gist.github.com/hrkrshnn/ee8fabd532058307229d65dcd5836ddc#the-increment-in-for-loop-post-condition-can-be-made-unchecked
    function uncheckedInc(
        uint16 i
    )
        internal
        pure 
        returns (uint16) 
    {
        unchecked {
            return i + 1;
        }
    }
}

/// ----------------------------------------------------------------------------
/// External Contracts
/// ----------------------------------------------------------------------------

// Primes NFT
//https://etherscan.io/address/0xBDA937F5C5f4eFB2261b6FcD25A71A1C350FdF20#code#L1507
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        _beforeTokenTransfer(from, to, id);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        _beforeTokenTransfer(address(0), to, id);

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        _beforeTokenTransfer(ERC721.ownerOf[id], address(0), id);

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /**
     * @dev OZ Hook that is called before any token transfer. This includes minting
     * and burning. For adding ERC721Enumerable functionality.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

error NotOwner();

abstract contract LilOwnable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external {
        if (msg.sender != _owner) revert NotOwner();

        _owner = _newOwner;
    }

    function renounceOwnership() public {
        if (msg.sender != _owner) revert NotOwner();

        _owner = address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/*
* @author: kethcode
*/

/// ----------------------------------------------------------------------------
/// Errors
/// ----------------------------------------------------------------------------

error NotAdmin();

abstract contract Adminlist {

    /// ------------------------------------------------------------------------
    /// Events
    /// ------------------------------------------------------------------------

    event AdminAddressAdded(address addr);
    event AdminAddressRemoved(address addr);

    /// ------------------------------------------------------------------------
    /// Variables
    /// ------------------------------------------------------------------------

    mapping(address => bool) public adminlist;

    /// ------------------------------------------------------------------------
    /// Modifiers
    /// ------------------------------------------------------------------------

    modifier onlyAdmin()
    {
        if(!adminlist[msg.sender]) revert NotAdmin();
        _;
    }

    /// ------------------------------------------------------------------------
    /// Functions
    /// ------------------------------------------------------------------------

    function addAddressToAdminlist(address addr) 
        public 
        onlyAdmin
        returns(bool success) 
    {
        if (!adminlist[addr]) {
            adminlist[addr] = true;
            emit AdminAddressAdded(addr);
            success = true; 
        }
    }

    function removeAddressFromAdminlist(address addr) 
        public 
        onlyAdmin
        returns(bool success) 
    {
        if (adminlist[addr]) {
            adminlist[addr] = false;
            emit AdminAddressRemoved(addr);
            success = true;
        }
    }

    function _setupAdmin(address addr) 
        internal 
        virtual 
    {
        adminlist[addr] = true;
        emit AdminAddressAdded(addr);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.6.0 <0.9.0;

// Thank you OpenZeppelin
import "@openzeppelin/contracts/utils/Strings.sol";

// Thank you tangert
// https://gist.github.com/tangert/1eceaf04f2877d84fb0e10681b39d7e3#file-renderer-sol

// Thanks GeeksForGeeks
// https://www.geeksforgeeks.org/random-number-generator-in-solidity-using-keccak256/

contract Renderer {
    constructor() {}

    function _render(uint256 id, string memory cohort)
        public
        pure
        returns (string memory)
    {
        string memory gradientStart = string(
            abi.encodePacked(
                "hsla(",
                Strings.toString(generateHighlightHue(id)),
                ", 100%, 50%, 1)"
            )
        );
        string memory gradientEnd = "hsla(250, 64%, 45%, 1)";
        string memory allGradients = renderAllGradients(
            gradientEnd,
            gradientStart
        );
        return
            string(
                abi.encodePacked(
                    '<svg width="500" height="500" viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="0.5" y="3.5" width="496" height="496" rx="41.5" fill="#8F8F8F" stroke="#838383" /><rect x="7.5" y="0.5" width="492" height="493" rx="41.5" fill="#EFEFEF" stroke="#C0C0C0" /><text x="352" y="64" fill="url(#titleGradient)" font-size="48px" font-weight="900" line-height="58px" letter-spacing="-2px" font-family="Inter,Arial,Helvetica,Apple Color Emoji,Segoe UI Emoji,NotoColorEmoji,Noto Color Emoji,Segoe UI Symbol,Android Emoji,EmojiSymbols,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica Neue,Noto Sans,sans-serif">30W3</text><text x="34" y="442" fill="url(#graduationGradient)" font-size="28px" font-weight="800" line-height="29px" letter-spacing="-1px" font-family="Inter,Arial,Helvetica,Apple Color Emoji,Segoe UI Emoji,NotoColorEmoji,Noto Color Emoji,Segoe UI Symbol,Android Emoji,EmojiSymbols,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica Neue,Noto Sans,sans-serif">Graduation</text><text x="34" y="464" fill="#29295E" font-size="22px" font-weight="bold" line-height="22px" letter-spacing="-1px" font-family="Inter,Arial,Helvetica,Apple Color Emoji,Segoe UI Emoji,NotoColorEmoji,Noto Color Emoji,Segoe UI Symbol,Android Emoji,EmojiSymbols,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica Neue,Noto Sans,sans-serif">',
                    cohort,
                    '</text><path id="diskEye" d="M250 156.975C196.884 156.975 147.486 188.44 131.859 238.309C142.609 285.427 196.884 319.642 250 319.642C303.116 319.642 354.992 288.177 368.141 238.309C352.332 188.44 303.116 156.975 250 156.975Z" fill="url(#diskEyeGradient)" /><path id="diskBottom" d="M250 316.642C196.884 316.642 151.313 284.34 131.859 238.309C125.381 253.638 121.798 270.489 121.798 288.177C121.798 358.982 179.196 416.38 250 416.38C320.804 416.38 378.202 358.982 378.202 288.177C378.202 270.489 374.62 253.638 368.141 238.309C348.687 284.34 303.116 316.642 250 316.642Z" fill="url(#diskBottomGradient)" /><path id="diskTop" d="M250 159.975C303.116 159.975 348.687 192.277 368.141 238.309C374.62 222.98 378.202 206.128 378.202 188.44C378.202 117.636 320.804 60.2375 250 60.2375C179.196 60.2375 121.798 117.636 121.798 188.44C121.798 206.128 125.381 222.98 131.859 238.309C151.313 192.277 196.884 159.975 250 159.975Z" fill="url(#diskTopGradient)" /><path id="diskPupil" d="M250 288.177C277.542 288.177 299.869 265.85 299.869 238.309C299.869 210.767 277.542 188.44 250 188.44C222.458 188.44 200.131 210.767 200.131 238.309C200.131 265.85 222.458 288.177 250 288.177Z" fill="url(#diskPupilGradient)" /><defs>',
                    allGradients,
                    '<linearGradient id="diskPupilGradient" x1="213.346" y1="202.702" x2="283.18" y2="270.54" gradientUnits="userSpaceOnUse"><stop stop-color="white" stop-opacity="0.8" /><stop offset="1" stop-color="white" stop-opacity="0.4" /></linearGradient></defs></svg>'
                )
            );
    }

    function renderGradient(
        string memory gradientStart,
        string memory gradientEnd,
        string memory id,
        string memory x1,
        string memory y1,
        string memory x2,
        string memory y2
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<linearGradient id="',
                    id,
                    '" x1="',
                    x1,
                    '" y1="',
                    y1,
                    '" x2="',
                    x2,
                    '" y2="',
                    y2,
                    '"  gradientUnits="userSpaceOnUse">',
                    '<stop stop-color="',
                    gradientStart,
                    '" /><stop offset="1" stop-color="',
                    gradientEnd,
                    '" /></linearGradient>'
                )
            );
    }

    function renderAllGradients(
        string memory gradientStart,
        string memory gradientEnd
    ) private pure returns (string memory) {
        string memory titleGradient = renderGradient(
            gradientStart,
            gradientEnd,
            "titleGradient",
            "352",
            "452",
            "64",
            "100"
        );
        string memory graduationGradient = renderGradient(
            gradientStart,
            gradientEnd,
            "graduationGradient",
            "34",
            "170",
            "442",
            "472"
        );
        string memory diskEyeGradient = renderGradient(
            gradientEnd,
            gradientStart,
            "diskEyeGradient",
            "379.203",
            "80.7484",
            "144.731",
            "367.874"
        );
        string memory diskBottomGradient = renderGradient(
            gradientEnd,
            gradientStart,
            "diskBottomGradient",
            "360.817",
            "349.878",
            "132.361",
            "268.073"
        );
        string memory diskTopGradient = renderGradient(
            gradientEnd,
            gradientStart,
            "diskTopGradient",
            "138.53",
            "119.249",
            "372.108",
            "225.058"
        );
        return
            string(
                abi.encodePacked(
                    titleGradient,
                    graduationGradient,
                    diskEyeGradient,
                    diskBottomGradient,
                    diskTopGradient
                )
            );
    }

    // In HSL color mode, the "H" parameters varies from 0 to 359
    function generateHighlightHue(uint256 id) private pure returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(id, "somesaltysalt", id))) % 359;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}