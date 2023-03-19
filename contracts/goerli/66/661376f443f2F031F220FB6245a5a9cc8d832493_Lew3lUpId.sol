// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ISBT721.sol";
import "./IERC721Metadata.sol";
import "./EnumerableMap.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC165.sol";

contract Lew3lUpId is Ownable, ERC165, ISBT721, IERC721Metadata {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    EnumerableMap.UintToAddressMap private _ownerMap;
    EnumerableMap.AddressToUintMap private _tokenMap;

    Counters.Counter private _tokenId;

    string public name;
    string public symbol;
    string private _baseTokenURI;
    address private _signer;
    address private _attester;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseTokenUri,
        address signer,
        address attester
    ) {
        name = tokenName;
        symbol = tokenSymbol;
        _baseTokenURI = baseTokenUri;
        _signer = signer;
        _attester = attester;
    }

    function setBaseTokenURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function setAttester(address attester) external onlyOwner {
        _attester = attester;
    }

    function attest(address to) external returns (uint256) {
        require(_msgSender() == _attester, "Forbidden");
        require(to != address(0), "Address is empty");
        require(!_tokenMap.contains(to), "Token already exists");

        _tokenId.increment();
        uint256 tokenId = _tokenId.current();

        _tokenMap.set(to, tokenId);
        _ownerMap.set(tokenId, to);

        emit Attest(to, tokenId);
        emit Transfer(address(0), to, tokenId);

        return tokenId;
    }

    function revoke(address from) external {
        require(_msgSender() == _attester, "Forbidden");
        require(from != address(0), "Address is empty");
        require(_tokenMap.contains(from), "The account does not have any token");

        uint256 tokenId = _tokenMap.get(from);

        _tokenMap.remove(from);
        _ownerMap.remove(tokenId);

        emit Revoke(from, tokenId);
        emit Transfer(from, address(0), tokenId);
    }

    function burn() external {
        address sender = _msgSender();

        require(
            _tokenMap.contains(sender),
            "The account does not have any token"
        );

        uint256 tokenId = _tokenMap.get(sender);

        _tokenMap.remove(sender);
        _ownerMap.remove(tokenId);

        emit Burn(sender, tokenId);
        emit Transfer(sender, address(0), tokenId);
    }

    function mint(bytes memory sign) external returns (uint256) {
        address to = _msgSender();
        require(!_tokenMap.contains(to), "Token already exists");
        require(_verifySignature(to, sign), "Incorrect signature");

        _tokenId.increment();
        uint256 tokenId = _tokenId.current();

        _tokenMap.set(to, tokenId);
        _ownerMap.set(tokenId, to);

        emit Attest(to, tokenId);
        emit Transfer(address(0), to, tokenId);

        return tokenId;
    }

    function balanceOf(address owner) external view returns (uint256) {
        (bool success, ) = _tokenMap.tryGet(owner);
        return success ? 1 : 0;
    }

    function tokenIdOf(address from) external view returns (uint256) {
        return _tokenMap.get(from, "The wallet has not attested any token");
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownerMap.get(tokenId, "Invalid tokenId");
    }

    function totalSupply() external view returns (uint256) {
        return _tokenMap.length();
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString())) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    function _verifySignature(address to, bytes memory sign) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(to))));
        address[] memory signList = _recoverAddresses(hash, sign);
        return signList[0] == _signer;
    }

    function _recoverAddresses(bytes32 hash, bytes memory signatures) pure internal returns (address[] memory addresses) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(signatures, i);
            addresses[i] = ecrecover(hash, v, r, s);
        }
    }

    function _parseSignature(bytes memory signatures, uint pos) pure internal returns (uint8 v, bytes32 r, bytes32 s) {
        uint offset = pos * 65;
        assembly {
            r := mload(add(signatures, add(32, offset)))
            s := mload(add(signatures, add(64, offset)))
            v := and(mload(add(signatures, add(65, offset))), 0xff)
        }
        if (v < 27) v += 27;
        require(v == 27 || v == 28);
    }

    function _countSignatures(bytes memory signatures) pure internal returns (uint) {
        return signatures.length % 65 == 0 ? signatures.length / 65 : 0;
    }
}