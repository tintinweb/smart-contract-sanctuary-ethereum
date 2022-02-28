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
//                       │ the batch was hard forked and 1555 DingBots were born │
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
    address private immutable T1 = 0x34567d53dd448feA28887fb5F76F80F544570d82;
    address private immutable T2 = 0xf9768dDf67125Cf3EBa2C8C73F59ed8f141F96D0;
    enum SalePhase {INIT, PUBLIC, CLOSED}
    /// @notice Price of one Dingbot in wei
    uint256 public constant PUBLIC_PRICE = 0.055 ether;
    /// @notice Mints allowed per address in the public sale
    uint256 public constant MINTS_PER_PUBLIC = 20;

    //---// State Variables //---//
    /// @notice Current sale phase
    /// `0` Sale has not yet begun
    /// `1` Public sale
    /// `2` Sale closed
    SalePhase public salePhase;
    /// @notice Amount of Dingbots minted in the public sale
    uint256 public publicCounter;
    /// @notice Amount of Dingbots minted from the reserved set
    uint256 public reservedCounter;
    /// @notice Highest Token ID
    uint256 public maxSupply = 1504;
    /// @notice Token URI prefix
    string public prefixURI;
    /// @notice How many tokens an address has minted in the public sale
    mapping (address => uint256) public mintCountPublic;

    constructor() ERC721("Dingbots Genesis", "DINGBOTS") {}

    //---// Override functions //---//
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(prefixURI).length > 0 ? string(abi.encodePacked(prefixURI, tokenId.toString(), ".json")) : "";
    }

    //---// Owner functions //---//
    /// @notice Set the token URI prefix, available if the URI has not yet been locked
    /// @param _newPrefixURI The new URI prefix
    function setPrefixURI(string memory _newPrefixURI) external onlyOwner {
        require(salePhase != SalePhase.CLOSED);
        prefixURI = _newPrefixURI;
    }

    /// @notice Set maximum mintable
    function setMaximumSupply(uint256 _newMax) external onlyOwner {
        require(salePhase != SalePhase.CLOSED);
        require(_newMax <= 1504);
        maxSupply = _newMax;
    }

    /// @notice Airdrop Dingbots in order to previous holders
    /// @param _tos the addresses to mint to
    function airdropToHolders(address[] calldata _tos) external onlyOwner {
        require(salePhase == SalePhase.INIT);
        for(uint i = 0; i < _tos.length; i++) {
            publicCounter += 1;
            _safeMint(_tos[i], publicCounter);
        }
    }

    /// @notice Increment the phase of the sale forward - check `salePhase` view function for current phase
    /// `0` Sale has not yet begun
    /// `1` Public sale
    /// `2` Closed
    function advanceSalePhase() external onlyOwner {
        salePhase = SalePhase(uint(salePhase) + 1);
    }

    /// @notice Mint a token from the reserved set to a specified address
    /// @param _tos The addresses to mint to
    /// @param _tokenIds The tokenIds to mint to the addresses
    function reservedMint(address[] calldata _tos, uint256[] calldata _tokenIds) external onlyOwner {
        require(_tos.length == _tokenIds.length, "Array sizes mismatched");
        for(uint i = 0; i < _tos.length; i++) {
            require(_tokenIds[i] <= 1555 && _tokenIds[i] >= 1505, "Dingbots: Not in reserved set");
            _safeMint(_tos[i], _tokenIds[i]);
        }
        reservedCounter += _tos.length;
    }

    /// @notice Withdraw sale ETH
    function withdrawETHTeam() external onlyOwner {
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
    function publicMint(uint256 _amount) external payable nonReentrant {
        require(salePhase == SalePhase.PUBLIC, "Dingbots: Public sale phase not running");
        require(_amount > 0 && mintCountPublic[msg.sender] + _amount <= MINTS_PER_PUBLIC, "Dingbots: Bad amount");
        require(publicCounter + _amount <= maxSupply, "Dingbots: Exceeds max supply");
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
}