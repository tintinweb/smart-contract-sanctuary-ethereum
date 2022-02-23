pragma solidity ^0.8.0;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

error ExceedMaxMint(); /// @notice Thrown when user attempts to exceed the mint limit per wallet.
error ExceedMaxSupply(); /// @notice Thrown when mint operation exceeds Louz max supply.
error AntiBot(); /// @notice Thrown when called by a contract.
error ValueTooLow(); /// @notice Thrown when users sends wrong ETH value.
error NotTokenOwner(); /// @notice Thrown when user operates an NFT from someone else.
error NotWhitelisted(); /// @notice Thrown when user is not whitelisted.
error SaleNotStartedOrEnded(); /// @notice Thrown if the the sale has not started or have already ended.

interface ILouzToken {
	function onTokenTransfer(address from, address to) external;
}

contract Louz is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    address public passwordSigner; // SIGNER ADDRESS

    ILouzToken public louzToken;

    uint public maxSupply = 7777; //first index is 0
    uint public mintPrice = 0.1 ether;

    bool public revealed = false;

    string public baseURI;
    string public unrevealedURI;

    uint public preSaleStartTime;
    uint public saleStartTime;
    uint public revealStartTime;

    mapping (address => uint256) private minted;

    constructor() ERC721A("Louz", "LOUZ") {
        _safeMint(msg.sender, 1);
    }

    function mintPreSale(uint tokenAmt, bytes memory signature) external payable {
        if(msg.sender != tx.origin) revert AntiBot(); // Anti-bot measure

        if(msg.value < tokenAmt * mintPrice) revert ValueTooLow();
        
        uint256 currentTime = block.timestamp;
        if(currentTime < preSaleStartTime || currentTime > saleStartTime) revert SaleNotStartedOrEnded();

        if(!isWhitelisted(msg.sender, signature)) revert NotWhitelisted();

        if(_numberMinted(msg.sender) + tokenAmt > 3) revert ExceedMaxMint();
        
        if(totalSupply() + tokenAmt > maxSupply) revert ExceedMaxSupply();

        _safeMint(msg.sender, tokenAmt);
    }

    function mint(uint tokenAmt) external payable {
        if(msg.sender != tx.origin) revert AntiBot(); // Anti-bot measure

        if(msg.value < tokenAmt * mintPrice) revert ValueTooLow();
        
        uint256 currentTime = block.timestamp;
        if(saleStartTime == 0 || currentTime < saleStartTime) revert SaleNotStartedOrEnded();

        if(minted[msg.sender] + tokenAmt > 5) revert ExceedMaxMint();
        
        if(totalSupply() + tokenAmt > maxSupply) revert ExceedMaxSupply();
        
        minted[msg.sender] += tokenAmt;
        _safeMint(msg.sender, tokenAmt);
    }

    function burnLouz(uint tokenId) public {
        if(msg.sender != ownerOf(tokenId)) revert NotTokenOwner();
        _burn(tokenId);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if(address(louzToken).code.length != 0)
            louzToken.onTokenTransfer(from, to);
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setTimeConfig(uint _preSaleStartTime, uint _saleStartTime, uint _revealStartTime) external onlyOwner {
        preSaleStartTime = _preSaleStartTime;
        saleStartTime = _saleStartTime;
        revealStartTime = _revealStartTime;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setLouzToken(address _louz) public onlyOwner {
		louzToken = ILouzToken(_louz);
	}

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
    
    function setUnrevealedURI(string memory newUnrevealedURI) public onlyOwner {
        unrevealedURI = newUnrevealedURI;
    }

    function setPasswordSigner(address signer) public onlyOwner {
        passwordSigner = signer;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        uint currentTime = block.timestamp;
        if(revealStartTime == 0 || currentTime < revealStartTime || bytes(baseURI).length == 0)
            return unrevealedURI;
        else
            return string(abi.encodePacked(baseURI, id.toString(), ".json"));
    }

    function isWhitelisted(address user, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encode(user));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == passwordSigner; //Verifies that the signer is the authenticator
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
        /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}