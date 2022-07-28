/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

pragma solidity ^0.8.0;


interface IERC721 {
    function tokenURI(uint256) external view returns (string memory);

    function setApprovalForAll(address operator, bool _approved) external;

    function mint(address, string calldata) external returns (uint256);

    function transferFrom(address, address, uint256) external;
}

contract BridgeContract {
    address constant hotwallet = address(0x51D87492c2FEf5a0edF6E23208D9a02C61b0d08B);
    address constant tokenContract = address(0xA813F6bb2a099b71bA6f397bc32563e2D45b0c76);

    mapping(uint256 => bool) public withdrawals;

    // version of the contract to prevent reusing signatures
    uint256 constant public CONTRACT_VERSION = 4;

    // asset_code that related to this bridge,
    // this contract operate with only one asset
    string constant ASSET_CODE = "nxnft";

    // indexes for packed signature parameters

    event Deposited(string tokendID, uint256 tokenID, string indexed asset_code);
    event Minted(string tokendID, string edition, uint256 tokenID, uint8 amount, string indexed asset_code, string externalID);
    event Withdrawn(uint256 reqID, uint256 tokenID, string indexed asset_code);

    function mint(
        string memory tokendID,
        string memory tokenURI,
        string memory externalID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external {
        _checkMintSignature(tokendID, tokenURI, "", 1, externalID, _r, _s, _v);

        uint256 tokenID = IERC721(tokenContract).mint(hotwallet, tokenURI);

        emit Minted(tokendID, "", tokenID, 1, ASSET_CODE, externalID);
    }

    function batchMint(
        string memory tokendID,
        string memory tokenURI,
        uint8 amount,
        string memory externalID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external {
        _checkMintSignature(tokendID, tokenURI, "", amount, externalID, _r, _s, _v);

        uint256 startID = IERC721(tokenContract).mint(hotwallet, tokenURI);

        for (uint8 i = 1; i < amount; i++) {
            IERC721(tokenContract).mint(hotwallet, tokenURI);
        }

        emit Minted(tokendID, "", startID, amount, ASSET_CODE, externalID);
    }

    function mintBySelf(
        string memory tokendID,
        string memory tokenURI,
        string memory externalID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external {
        _checkMintSignature(tokendID, tokenURI, "", 1, externalID, _r, _s, _v);

        uint256 tokenID = IERC721(tokenContract).mint(msg.sender, tokenURI);
        IERC721(tokenContract).transferFrom(msg.sender, hotwallet, tokenID);

        emit Minted(tokendID, "", tokenID, 1, ASSET_CODE, externalID);
    }

    function batchMintBySelf(
        string memory tokendID,
        string memory tokenURI,
        string memory edition,
        uint8 amount,
        string memory externalID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external {
        _checkMintSignature(tokendID, tokenURI, edition, amount, externalID, _r, _s, _v);

        uint256 startID = IERC721(tokenContract).mint(msg.sender, tokenURI);
        IERC721(tokenContract).transferFrom(msg.sender, hotwallet, startID);

        for (uint8 i = 1; i < amount; i++) {
            IERC721(tokenContract).transferFrom(msg.sender, hotwallet, IERC721(tokenContract).mint(msg.sender, tokenURI));
        }

        emit Minted(tokendID, edition, startID, amount, ASSET_CODE, externalID);
    }

    function deposit(
        string memory tokendID,
        uint256 tokenID
    ) external {
        IERC721(tokenContract).transferFrom(msg.sender, hotwallet, tokenID);
        emit Deposited(tokendID, tokenID, ASSET_CODE);
    }

    function withdraw(
        uint256 withdrawID,
        uint256 timestamp,
        uint256 tokenID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external {
        require(!withdrawals[withdrawID], "such-withdraw-already-used");

        _checkWithdrawSignature(timestamp, withdrawID, tokenID, _r, _s, _v);
        _withdrawFromHotwallet(msg.sender, tokenID, withdrawID);
    }

    function lazyWithdraw(
        uint256 withdrawID,
        uint256 timestamp,
        string memory tokenURI,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external {
        require(!withdrawals[withdrawID], "such-withdraw-already-used");

        _checkWithdrawSignature(timestamp, withdrawID, 0, _r, _s, _v);
        _withdrawFromHotwallet(msg.sender, IERC721(tokenContract).mint(hotwallet, tokenURI), withdrawID);
    }

    function _withdrawFromHotwallet(
        address receiver,
        uint256 tokenID,
        uint256 withdrawID
    ) internal {
        IERC721(tokenContract).transferFrom(hotwallet, receiver, tokenID);
        withdrawals[withdrawID] = true;
        emit Withdrawn(withdrawID, tokenID, ASSET_CODE);
    }

    function _checkWithdrawSignature(
        uint256 _timestamp,
        uint256 _requestID,
        uint256 _tokenID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) internal view {
        require(_timestamp >= block.timestamp, "signature-expired");

        bytes32 _hash = keccak256(abi.encodePacked(CONTRACT_VERSION, _timestamp, msg.sender, _requestID, _tokenID));

        _checkSig(_hash, _r, _s, _v);
    }

    function _checkMintSignature(
        string memory _tokendID,
        string memory _tokenURI,
        string memory _edition,
        uint8 _amount,
        string memory _externalID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) internal pure {
        bytes32 _hash = keccak256(abi.encodePacked(CONTRACT_VERSION, _tokendID, _tokenURI, _edition, _amount, _externalID));

        _checkSig(_hash, _r, _s, _v);
    }

    function _checkSig(
        bytes32 _hash,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) internal pure {
        address _signer = ecrecover(_hash, _v, _r, _s);

        require(_signer != address(0), "signature-invalid");
        require(hotwallet == _signer, "bad-signature");
    }
}