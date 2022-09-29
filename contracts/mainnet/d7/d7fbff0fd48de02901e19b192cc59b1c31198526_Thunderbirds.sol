// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./ERC721.sol";
import "./Ownership.sol";

interface IMintPass {
    function getRedeemedTimes(uint256 tokenId) external view returns(uint8);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address _owner) external view returns (uint256);
    function exists(uint256 _tokenId) external view returns (bool);
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 _tokenId);
    function updateRedeemedTimes(uint256 tokenId, uint8 _redeemedTimes) external;
}

contract Thunderbirds is ERC721, Ownership {

    uint256 public maxSupply; // max supply of nft
    uint256 public preSaleStarts;
    uint256 public preSaleEnds;
    uint256 public saleEnds;
    IMintPass private mintPass;
    bool public isPaused = false; // pause the contractn when something goes "really" wrong
    uint256 public price;
    address payable public coldWallet;
    uint256 public mintedForTeam;
    bool public isRevealed;

    uint256 private constant reservedForTeam = 30;
    uint8 private constant MAX_REDEEME_COUNT = 3;

    // nonce to prevent replay attack on admin signature
    mapping(address => mapping(uint => bool)) public isSignerNonceUsed;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }


    event Paused(bool _isPaused);
    event PriceUpdate(uint256 oldPrice, uint256 newPrice);


    modifier notPaused() {
        require(!isPaused, "Contract paused");
        _;
    }
    

    modifier canMint(uint8 quantity) {
        require(block.timestamp >= preSaleStarts , "Sale not live yet");
        require(block.timestamp < saleEnds, "Sale closed");
        require(totalSupply() + quantity <= maxSupply - reservedForTeam, "Sold out");
        require(msg.value == price*quantity, "Incorrect fee");
        _;
    }


    constructor(
        address _mintPassContract,
        uint256 _preSaleStarts,
        uint256 _preSaleEnds,
        address payable _coldWallet,
        uint256 _price,
        string memory _baseurl
    )
        ERC721("Thunderbirds International Rescue Club", "FAB", _baseurl, ".json")
    {
        mintPass = IMintPass(_mintPassContract);
        maxSupply = 5432;
        price = _price;
        coldWallet = _coldWallet;
        preSaleStarts = _preSaleStarts;
        preSaleEnds = _preSaleEnds;
        saleEnds = preSaleEnds + 1 weeks;
        isRevealed = false;
    }

    function mint(address user, uint8 quantity) public payable canMint(quantity) notPaused {
        require(block.timestamp >= preSaleEnds, "Only mintpass holders allowed in presale");
        coldWallet.transfer(msg.value);
        _batchMint(user, quantity);
    }

    function mintWithPass(address user, uint8 quantity, uint256 mintPassId) public payable canMint(quantity) {
        require(block.timestamp < preSaleEnds, "Pre-sale ended");
        require(mintPass.exists(mintPassId), "Invalid mint pass");
        require(mintPass.ownerOf(mintPassId) == msg.sender, "Sender does not own given mint pass");
        coldWallet.transfer(msg.value);
        uint8 redeemedTimes = mintPass.getRedeemedTimes(mintPassId);
        require(redeemedTimes+quantity <= MAX_REDEEME_COUNT, "Mint pass redeemed");
        mintPass.updateRedeemedTimes(mintPassId, redeemedTimes+quantity);
        _batchMint(user, quantity);
    }

    function mintReservedTokens(address[] memory users) public onlyDeputyOrOwner {
        require(mintedForTeam + users.length <= reservedForTeam, "Max reserved tokens minted");
        unchecked {
            mintedForTeam += users.length;
        }
        for(uint8 i=0; i<users.length; i++) {
            super.mint(users[i], totalSupply()+1);
        }
    }


    function updatePrice(uint256 _price) public onlyOwner {
        emit PriceUpdate(price, _price);
        price = _price;
    }


    function _batchMint(address user, uint8 quantity) internal  {
        for(uint8 i=0; i<quantity; i++) {
            super.mint(user, totalSupply() + 1);
        }
    }

    
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override notPaused {
        super._transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override notPaused {
        super._safeTransferFrom(_from, _to, _tokenId, "0x");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override notPaused {
        super._safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function burn(uint256 _tokenId) public override notPaused {
        super.burn(_tokenId);
    }
    
    function preAuthTransfer(
        address _from, address _to, uint256 _tokenId, uint256 signerNonce, Signature memory signature
    ) public notPaused {
        require(
            !isSignerNonceUsed[_from][signerNonce],
            "Duplicate nonce in signature"
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes4(keccak256("transfer")),
                address(this),
                signerNonce,
                getChainID(),
                _from,
                _to,
                _tokenId
            )
        );
        address signer = getSigner(hash, signature);
        require(signer == _from, "Owner and signer don't match");
        isSignerNonceUsed[signer][signerNonce] = true;
        super._transferOnBehalf(signer, _to, _tokenId);
    }

    function updateBaseTokenUri(string memory _baseTokenUri) public onlyOwner {
        super._updateBaseTokenUri(_baseTokenUri);
    }

    function pauseContract(bool _isPaused) public onlyOwner{
        isPaused = _isPaused;
        emit Paused(_isPaused);
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(exists(_tokenId), "Asset does not exist");
        if(!isRevealed) return baseTokenURI;
        return super._tokenURI(_tokenId);
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

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

}