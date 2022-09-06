// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./ERC721.sol";
import "./Ownership.sol";

contract MintPass is ERC721, Ownership {
    // represents how many times a mint pass is redeemed.
    mapping(uint256 => uint8) private redeemedTimes;
    // contracts that can update mint pass uses, like when minting art, art nft will updated `redeemedTimes`
    mapping(address => bool) public isWhitelisted;
    // nonce to prevent replay attack on admin signature
    mapping(uint256 => bool) public isSignerNonceUsed;

    bool public mintStoppted; // when enabled no futher mint pass can be minted.
    uint256 public maxSupply; // max supply of mint pass
    bool public isPaused = false; // pause the contractn when something goes "really" wrong

    uint8 constant UINT8_MAX = 255;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    event MintPassUpdated(
        uint256 tokenId,
        uint8 redeemedTimes,
        address updatedBy
    );

    event Paused(bool _isPaused);

    modifier canAcceptMintPass(address user) {
        require(balanceOf(user) == 0, "Only 1 mint pass allowed per user");
        _;
    }

    modifier mintAllowed() {
        require(!mintStoppted, "Minting stopped");
        _;
    }

    modifier notPaused() {
        require(!isPaused, "Contract paused");
        _;
    }

    constructor(string memory _baseTokenUri)
        ERC721("Thunderbirds: IRC Mint Pass", "TBMP", _baseTokenUri)
    {
        maxSupply = 1000;
    }

    function mint(
        address user,
        Signature memory adminSignature,
        uint256 signerNonce
    ) public canAcceptMintPass(user) mintAllowed notPaused {
        require(totalSupply() < maxSupply, "Max token minted");
        require(
            !isSignerNonceUsed[signerNonce],
            "Duplicate nonce in signature"
        );
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes4(keccak256("mint")),
                address(this),
                signerNonce,
                getChainID(),
                user
            )
        );
        address signer = getSigner(hash, adminSignature);
        require(isDeputyOwner[signer], "Invalid signature/message");
        isSignerNonceUsed[signerNonce] = true;
        string memory url = "QmXyV2HUP7hv8Xjx3X6ZLUUMHkxsdRuQhZ9DwpzZqH16jD";
        super.mint(user, totalSupply() + 1, url);
    }

    function batchMintByAdmin(address[] memory users) public mintAllowed onlyDeputyOrOwner {
        require(totalSupply() + users.length < maxSupply, "Max token minted");
        string memory url = "QmXyV2HUP7hv8Xjx3X6ZLUUMHkxsdRuQhZ9DwpzZqH16jD";
        for(uint8 i=0; i<users.length; i++) {
            require(balanceOf(users[i]) == 0, "Only 1 mint pass allowed per user");
            super.mint(users[i], totalSupply() + 1, url);
        }
    }

    function updateRedeemedTimes(uint256 tokenId, uint8 _redeemedTimes)
        public
        notPaused
    {
        require(isWhitelisted[msg.sender], "Caller not whitelisted");
        redeemedTimes[tokenId] = _redeemedTimes;
        emit MintPassUpdated(tokenId, _redeemedTimes, msg.sender);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override canAcceptMintPass(_to) notPaused {
        super._transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override canAcceptMintPass(_to) notPaused {
        super._safeTransferFrom(_from, _to, _tokenId, "0x");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override canAcceptMintPass(_to) notPaused {
        super._safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function burn(uint256 _tokenId) public override notPaused {
        super.burn(_tokenId);
    }
    

    function updateTokenUri(uint256 _tokenId, string memory _url)
        public
        onlyDeputyOrOwner
    {
        super._updateTokenUri(_tokenId, _url);
    }

    function updateBaseTokenUri(string memory _baseTokenUri) public onlyOwner {
        super._updateBaseTokenUri(_baseTokenUri);
    }

    function whitelistContract(address contractAddress) public onlyOwner {
        isWhitelisted[contractAddress] = true;
    }

    function removeFromWhitelist(address contractAddress) public onlyOwner {
        isWhitelisted[contractAddress] = false;
    }

    function disableMinting(bool shoudlStop) public onlyOwner {
        mintStoppted = shoudlStop;
    }

    function pauseContract(bool _isPaused) public onlyOwner returns (bool) {
        isPaused = _isPaused;
        emit Paused(_isPaused);
        return true;
    }

    function getSigner(bytes32 message, Signature memory sig)
        public
        pure
        returns (address)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
        address signer = ecrecover(prefixedHash, sig.v, sig.r, sig.s);
        return signer;
    }

    function getRedeemedTimes(uint256 tokenId) public view returns(uint8) {
        if(!exists(tokenId)) return UINT8_MAX;
        return redeemedTimes[tokenId];
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}