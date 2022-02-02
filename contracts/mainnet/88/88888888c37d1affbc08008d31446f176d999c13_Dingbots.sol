// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%(*,,,*(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/                                 (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@                                               @@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@%                                                       &@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@                                                               @@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@                                                                     @@@@@@@@@@@@@@@
// @@@@@@@@@@@@@%                                                                         @@@@@@@@@@@@@
// @@@@@@@@@@@,                                                                             #@@@@@@@@@@
// @@@@@@@@@@             &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#             @@@@@@@@@
// @@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#           @@@@@@@
// @@@@@@@          &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@
// @@@@@@          /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@
// @@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@
// @@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           ,@@@
// @@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@
// @@@@            @@@@@@@@,                       @@@@@                       #@@@@@@@@            @@@
// @@@@           /@@@@@@@@                        @@@@@                        @@@@@@@@            @@@
// @@@@           @@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@           [email protected]@@@@@@@@@@@@@*           @@@
// @@@@           @@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@          (@@@
// @@@@@          %@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@         (@@@@@@@@@@@@@@@           @@@@
// @@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@
// @@@@@@@                    ./&@@@@@@@@@@@@@@@%         &@@@@@@@@@@@@@@@&/                    #@@@@@@
// @@@@@@@@@                                                                                   @@@@@@@@
// @@@@@@@@@@@                                                                               @@@@@@@@@@
// @@@@@@@@@@@@@@                                                                         @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@                                                                  /@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@(                                          ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//
//                       ┌───────────────────────────────────────────────────────┐
//                       │  After order 66 was deemed defective by Hasbruh Toys, │
//                       │ the batch was hard forked and 9999 DingBots were born │
//                       │                                                       │
//                       │  Rebuilt by an ethereum workforce of senior citizens  │
//                       │ and parts sourced by local garage sales… they may not │
//                       │     be the brightest bunch but damn they’re cute!     │
//                       └───────────────────────────────────────────────────────┘
//
//                                     ┌──────────────────────────┐
//                                     │ https://dingbotsnft.com/ │
//                                     └──────────────────────────┘

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "ERC721.sol";
import "Ownable.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";

interface IERC20 {function transfer(address recipient, uint256 amount) external returns (bool);}

contract Dingbots is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    //---// Constant Variables //---//
    address private immutable SIGNER = 0x35C40ec37Ab0206965581d36d73cBC2098DbC8e2;
    address private immutable T1 = 0x34567d53dd448feA28887fb5F76F80F544570d82;
    address private immutable T2 = 0xf9768dDf67125Cf3EBa2C8C73F59ed8f141F96D0;
    enum SalePhase {INIT, PRESALE, PUBLIC}
    /// @notice Price of one presale Dingbot in wei
    uint256 public constant PRESALE_PRICE = 0.04 ether;
    /// @notice Price of one Dingbot in wei
    uint256 public constant PUBLIC_PRICE = 0.055 ether;
    /// @notice Amount of Dingbots not available for sale
    uint256 public constant RESERVED_SET_SIZE = 50;
    /// @notice Highest Token ID
    uint256 public constant MAX_SUPPLY = 10000;
    /// @notice Mints allowed per approved presale address
    uint256 public constant MINTS_PER_PRESALER = 2;
    /// @notice Mints allowed per address in the public sale
    uint256 public constant MINTS_PER_PUBLIC = 20;

    //---// State Variables //---//
    /// @notice Current sale phase
    /// `0` Sale has not yet begun
    /// `1` Presale
    /// `2` Public sale
    SalePhase public salePhase;
    /// @notice Amount of Dingbots minted in the public sale
    uint256 public publicCounter;
    /// @notice Amount of Dingbots minted from the reserved set
    uint256 public reservedCounter;
    /// @notice Token URI prefix
    string public prefixURI;
    /// @notice True if the URI is frozen and may no longer be changed
    bool public URILocked;
    bool private t1Withdrawn;
    mapping (address => uint256) public mintCountPresale;
    mapping (address => uint256) public mintCountPublic;

    constructor() ERC721("Dingbots", "DINGBOTS") {}

    //---// Override functions //---//
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(prefixURI).length > 0 ? string(abi.encodePacked(prefixURI, tokenId.toString(), ".json")) : "";
    }

    //---// Owner functions //---//
    /// @notice Set the token URI prefix, available if the URI has not yet been locked
    /// @param _newPrefixURI The new URI prefix
    function setPrefixURI(string memory _newPrefixURI) external onlyOwner {
        require(!URILocked);
        prefixURI = _newPrefixURI;
    }

    /// @notice Lock the token URI prefix
    function lockURI() external onlyOwner {
        URILocked = true;
    }

    /// @notice Increment the phase of the sale forward - check `salePhase` view function for current phase
    /// `0` Sale has not yet begun
    /// `1` Presale
    /// `2` Public sale
    function advanceSalePhase() external onlyOwner {
        salePhase = SalePhase(uint(salePhase) + 1);
    }

    /// @notice Mint a token from the reserved set to a specified address
    /// @param _to The address to mint to
    /// @param _tokenId The tokenId to mint to the address
    function reservedMint(address _to, uint256 _tokenId) external onlyOwner {
        require(_tokenId <= MAX_SUPPLY && _tokenId >= MAX_SUPPLY - RESERVED_SET_SIZE + 1, "Dingbots: Not in reserved set");
        reservedCounter += 1;
        _safeMint(_to, _tokenId);
    }

    /// @notice Withdraw T1 ETH
    function withdrawETHT1() external onlyOwner {
        t1Withdrawn = true;
        payable(T1).transfer(3 ether);
    }

    /// @notice Withdraw sale ETH
    function withdrawETHTeam() external onlyOwner {
        require(t1Withdrawn);
        uint256 _balance = address(this).balance;
        uint256 _t1 = _balance * 15 / 100; // 15%
        uint256 _t2 = _balance - _t1; // 85%
        payable(T1).transfer(_t1);
        payable(T2).transfer(_t2);
    }

    /// @notice Recover an ERC20 token mistakenly sent to this contract
    /// @param _t The address of the ERC20 token
    /// @param _r The recipient of the ERC20 token recovery
    /// @param _a The amount of tokens to recover
    function recoverERC20(IERC20 _t, address _r, uint256 _a) external onlyOwner {
        _t.transfer(_r, _a);
    }

    //---// Public functions //---//
    function presaleMint(bytes32 _r, bytes32 _s, uint8 _v, uint256 _amount) external payable {
        require(salePhase == SalePhase.PRESALE, "Dingbots: Presale phase not running");
        bytes32 _msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n20", msg.sender));
        require(ecrecover(_msgHash, _v, _r, _s) == SIGNER, "Dingbots: Invalid signature");
        require(_amount > 0 && mintCountPresale[msg.sender] + _amount <= MINTS_PER_PRESALER, "Dingbots: Bad amount");
        require(publicCounter + _amount <= MAX_SUPPLY - RESERVED_SET_SIZE, "Dingbots: Exceeds max supply");
        require(msg.value >= _amount * PRESALE_PRICE, "Dingbots: Bad price");
        mintCountPresale[msg.sender] += _amount;
        for(uint i = 0; i < _amount; i++) {
            publicCounter += 1;
            _safeMint(msg.sender, publicCounter);
		}
    }

    function publicMint(uint256 _amount) external payable nonReentrant {
        require(salePhase == SalePhase.PUBLIC, "Dingbots: Public sale phase not running");
        require(_amount > 0 && mintCountPublic[msg.sender] + _amount <= MINTS_PER_PUBLIC, "Dingbots: Bad amount");
        require(publicCounter + _amount <= MAX_SUPPLY - RESERVED_SET_SIZE, "Dingbots: Exceeds max supply");
        require(msg.value >= _amount * PUBLIC_PRICE, "Dingbots: Bad price");
        mintCountPublic[msg.sender] += _amount;
        for(uint i = 0; i < _amount; i++) {
            publicCounter += 1;
            _safeMint(msg.sender, publicCounter);
        }
    }

    //---// View functions //---//
    function contractURI() public view returns (string memory) {
        return bytes(prefixURI).length > 0 ? string(abi.encodePacked(prefixURI, "dingbots.json")) : "";
    }

    function totalSupply() public view returns(uint256) {
        return publicCounter + reservedCounter;
    }
	
	function contractBalance() public view returns(uint256) {
		return address(this).balance;
	}
}