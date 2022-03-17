// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract NftPassport is ERC721, Ownable {
    using Strings for uint256;

    uint16 public chainId;
    uint public verifiersAdded = 0;
    uint public passportsMinted = 0;

    struct Verifier {
        address payable feeReceiver;
        address dataSigner;
        uint mintFee;
        string baseUri;
        bool active;
    }
    mapping(uint => Verifier) public verifiers;

    struct PassportData {
        uint verifierId;
        address owner;
        string nickname;
        uint16 country;
        uint32 birthDate;
    }
    mapping(uint => PassportData) public passports;

    event VerifierAdd(uint indexed verifierId, address payable feeReceiver, address dataSigner, uint mintFee, string baseUri);
    event VerifierUpdate(uint indexed verifierId, address payable feeReceiver, address dataSigner, uint mintFee, bool active, string baseUri);
    event PassportMint(address indexed owner, uint indexed passportId, uint indexed verifierId, string nickname);
    event PassportUpdate(address indexed owner, uint indexed passportId, uint16 country, uint32 birthDate);
    event PassportBurn(address indexed owner, uint indexed passportId);
    event NicknameUpdate(address indexed owner, uint indexed passportId, string nickname);

    constructor(uint16 _chainId) ERC721("NFT Passport", "NFTID") {
        chainId = _chainId;
    }

    function addVerifier(address payable _feeReceiver, address _dataSigner, uint _mintFee, string calldata _baseUri) public onlyOwner {
        uint verifierId = verifiersAdded;
        verifiers[verifierId] = Verifier(_feeReceiver, _dataSigner, _mintFee, _baseUri, true);
        verifiersAdded++;
        emit VerifierAdd(verifierId, _feeReceiver, _dataSigner, _mintFee, _baseUri);
    }

    function updateVerifier(uint _verifierId, address payable _feeReceiver, address _dataSigner, uint _mintFee, string calldata _baseUri) public onlyOwner {
        require(_verifierId < verifiersAdded, "Incorrect verifier ID");
        verifiers[_verifierId].feeReceiver = _feeReceiver;
        verifiers[_verifierId].dataSigner = _dataSigner;
        verifiers[_verifierId].mintFee = _mintFee;
        verifiers[_verifierId].baseUri = _baseUri;
        emit VerifierUpdate(_verifierId, _feeReceiver, _dataSigner, _mintFee, verifiers[_verifierId].active, _baseUri);
    }

    function activateVerifier(uint _verifierId) public onlyOwner {
        require(_verifierId < verifiersAdded, "Incorrect verifier ID");
        require(verifiers[_verifierId].active == false, "The verifier is already active");
        verifiers[_verifierId].active = true;
        emit VerifierUpdate(
            _verifierId,
            verifiers[_verifierId].feeReceiver,
            verifiers[_verifierId].dataSigner,
            verifiers[_verifierId].mintFee,
            true,
            verifiers[_verifierId].baseUri
        );
    }

    function deactivateVerifier(uint _verifierId) public onlyOwner {
        require(_verifierId < verifiersAdded, "Incorrect verifier ID");
        require(verifiers[_verifierId].active == true, "The verifier is already inactive");
        verifiers[_verifierId].active = false;
        emit VerifierUpdate(
            _verifierId,
            verifiers[_verifierId].feeReceiver,
            verifiers[_verifierId].dataSigner,
            verifiers[_verifierId].mintFee,
            false,
            verifiers[_verifierId].baseUri
        );
    }

    function mintPassport(uint _verifierId, string calldata _nickname) external payable {
        require(_verifierId < verifiersAdded, "Incorrect verifier ID");
        require(verifiers[_verifierId].active == true, "Incorrect verifier ID");
        require(msg.value == verifiers[_verifierId].mintFee, "Incorrect fee amount");
        verifiers[_verifierId].feeReceiver.transfer(msg.value);
        uint id = passportsMinted;
        _safeMint(msg.sender, id);
        passports[id] = PassportData(_verifierId, msg.sender, _nickname, 0, 0);
        passportsMinted++;
        emit PassportMint(msg.sender, id, _verifierId, _nickname);
    }

    function updateNickname(uint _id, string calldata _nickname) external {
        require(_isApprovedOrOwner(msg.sender, _id), "Forbidden");
        passports[_id].nickname = _nickname;
        emit NicknameUpdate(msg.sender, _id, _nickname);
    }

    function setPassportData(uint _id, uint16 _country, uint32 _birthDate, bytes memory _sign) external {
        require(_isApprovedOrOwner(msg.sender, _id), "Forbidden");
        require(passports[_id].country == 0 && passports[_id].birthDate == 0, "The data is already specified");
        address signer = verifiers[passports[_id].verifierId].dataSigner;
        require(_verifySignature(_id, _country, _birthDate, signer, _sign), "Incorrect signature");
        passports[_id].country = _country;
        passports[_id].birthDate = _birthDate;
        emit PassportUpdate(msg.sender, _id, _country, _birthDate);
    }

    function burnPassport(uint _id) external {
        require(_isApprovedOrOwner(msg.sender, _id), "Forbidden");
        _burn(_id);
        passports[_id] = PassportData(0, address(0), "", 0, 0);
        emit PassportBurn(msg.sender, _id);
    }

    function getUserPassport(address _owner, uint _index) external view returns (
        uint passportId,
        uint verifierId,
        address owner,
        string memory nickname,
        uint16 country,
        uint32 birthDate,
        string memory uri
    ) {
        uint currentIndex = 0;
        for (uint i = 0; i < passportsMinted; i++) {
            if (_isApprovedOrOwner(_owner, i)) {
                if (currentIndex == _index) {
                    return(
                        i,
                        passports[i].verifierId,
                        passports[i].owner,
                        passports[i].nickname,
                        passports[i].country,
                        passports[i].birthDate,
                        tokenURI(i)
                    );
                }
                currentIndex++;
            }
        }
        revert("The passport does not exist");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory baseURI = verifiers[passports[tokenId].verifierId].baseUri;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _verifySignature(uint _id, uint16 _country, uint32 _birthDate, address _signer, bytes memory _sign) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(chainId, _id, _country, _birthDate))
            ));
        address[] memory signList = _recoverAddresses(hash, _sign);
        return signList[0] == _signer;
    }

    function _recoverAddresses(bytes32 _hash, bytes memory _signatures) pure internal returns (address[] memory addresses) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }

    function _parseSignature(bytes memory _signatures, uint _pos) pure internal returns (uint8 v, bytes32 r, bytes32 s) {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }
        if (v < 27) v += 27;
        require(v == 27 || v == 28);
    }

    function _countSignatures(bytes memory _signatures) pure internal returns (uint) {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }
}