/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

contract KryptoriaTest {
    using Strings for uint256;

    address private _address1 = 0x474a08aBEc6eBd709a941000acD4c1EF21F9B721;
    address private _address2 = 0x4CaCc7773dB97736737308e75D914B374fF9E795;

    // Address to validate signature for update token uri
    address private _platformAddress = 0xdf619A92247492c28Aed1CC69529bbdF8B1a9BC4;

    // boolean to control NFT reveal 
    bool private _revealed = false;

    // Owner Address
    address private _ownerAddress;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // TokenId to staking start time (0 means not staking)
    mapping(uint256 => uint) private _stakingStartTime;

    // Mapping for token to total staking time
    mapping(uint256 => uint256) private _totalSakingTime;

    // Mapping for wallet to whitelisting
    mapping(address => bool) private _isUserWhiteListed;

    // Mapping to hold token minted per wallet
    mapping(address => uint) private _userTokenCount;

    // Total supply of the NFTs
    uint public _totalSupply ;

    // variable to store miniting status (0-off, 1-only whitelisted, 2-open for all)
    uint private _mintStatus = 0;

    // Whether staking is currently allowed or not
    bool public _stakingOpen = false;

    string public _notRevealedUri = "ipfs://QmaVbaSvU3gTKBM2uKeTSFj15QmmEqe5rQPWxNpr82umgG";

    string public _baseURI;

    constructor() {
        _ownerAddress = msg.sender;

        // mint the token for given addresss
        _owners[1] = _address1;
         _userTokenCount[_address1] += 1;
        _owners[2] = _address2;
        _userTokenCount[_address2] += 1;
        _owners[3] = _address1;
        _userTokenCount[_address1] += 1;
        _owners[4] = _address1;
        _userTokenCount[_address1] += 1;
        _totalSupply += 4;
    }

    function reveal() public {
        require(msg.sender == _ownerAddress, "only owner can reveal");
        _revealed = true;
    }

    function isRevealed() public view returns(bool) {
        return _revealed;
    }

    function unReveal() public {
        require(msg.sender == _ownerAddress, "only owner can make reveal false");
        _revealed = false;
    }

    function getStakingTime(uint256 tokenId)
        external
        view
        returns (
            bool isStaked,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = _stakingStartTime[tokenId];
        if (start != 0) {
            isStaked = true;
            current = block.timestamp - start;
        }
        total = current + _totalSakingTime[tokenId];
    }

    function isWhiteListed(address wallet) public view returns(bool) {
        return _isUserWhiteListed[wallet];
    }

    function setUserWhiteListed(address[] calldata wallets) public {
        require(msg.sender == _ownerAddress, "only owner is allowed");
        for (uint256 i = 0; i < wallets.length; ++i) {
            _isUserWhiteListed[wallets[i]] = true;
        }
    }

    // 0 => Minting close for all
    // 1 => Minting is only open for whitelisted
    // 2 => Minting open for all
    function setMintingStatus(uint status) public {
        require(msg.sender == _ownerAddress, "only owner can set");
        require(status <= 2, "allowed values are 0,1 and 2");
        _mintStatus = status;
    }

    function getMintingStatus() public view returns(string memory) {
        if(_mintStatus == 0) {
            return "Minting is closed for all";
        } else if(_mintStatus == 1) {
            return "Minting is only available for white listed users";
        } else if(_mintStatus == 2) {
            return "Minting is open for all users";
        } else {
            return "Something went wrong";
        }
    }

    function getTokenCount(address user) public view returns(uint) {
        return _userTokenCount[user];
    }

    function getTokenOwner(uint256 tokenId) public view returns(address) {
        return _owners[tokenId];
    }
    

    function safeMint(uint256 tokenId) public {
        require(_totalSupply < 10000, "platform reached limit of minting");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(_mintStatus != 0, "minting is closed for all");
        if(_mintStatus == 1) {
            require(_isUserWhiteListed[msg.sender], "you are not whitelisted, please contact administrator");
        }
        require((_userTokenCount[msg.sender] + 1) <= 5, "you cant mint more then 5");
        _owners[tokenId] = msg.sender;
        _userTokenCount[msg.sender] += 1;
        _totalSupply+=1;
    }

    function setBaseURI(string memory baseURI) public {
        require(msg.sender == _ownerAddress, "only owner can set uri");
        require(_revealed == false, "Only allowed to set when its not reveled");
        _baseURI = baseURI;
    }

    function updateTokenURI(uint256 tokenId, string memory uri, bytes memory sig) public {
        require(_exists(tokenId), "requesting for non existing tokenId");
        require(_owners[tokenId] == msg.sender, "you are not the owner of this nft");
        require(_revealed == true, "only allowed to update after reveal");
        bool isValid = isValidURI(uri, sig);
        require(isValid == true, "signature validation failed!");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        if(_revealed == false) {
            return _notRevealedUri;
        }
        if(bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        }
        return string(abi.encodePacked(_baseURI, tokenId.toString(), ".json"));
    }

    // Toggles the `stakingOpen` flag
    function setStakingOpen(bool open) external {
        require(msg.sender == _ownerAddress, "only owner can set");
        _stakingOpen = open;
    }

    function stakeNfts(uint256[] memory _tokenIds) public {
        require(_stakingOpen, "staking is closed");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "requesting for non existing tokenId");
            require(_owners[_tokenIds[i]] == msg.sender, "you are not the owner of this nft");
            require(_stakingStartTime[_tokenIds[i]] == 0, "NFT is already staked");
            _stakingStartTime[_tokenIds[i]] = block.timestamp;
        }
    }

    function unstakeNfts(uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "this tokenId does not exist");
            require(_owners[_tokenIds[i]]== msg.sender || msg.sender == _ownerAddress, "you are not the owner of this nft");
            require(_stakingStartTime[_tokenIds[i]] != 0, "NFT is not on stake");
            uint256 start = block.timestamp - _stakingStartTime[_tokenIds[i]];
            _totalSakingTime[_tokenIds[i]] += start;
            _stakingStartTime[_tokenIds[i]] = 0;
        }
    }

    function isValidURI(string memory _uri, bytes memory sig) internal view returns(bool) {
        bytes32 message = keccak256(abi.encodePacked(_uri));
        return (recoverSigner(message, sig) == _platformAddress);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
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
}