//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./OwnableWithAdmin.sol";
import "./Strings.sol";
import "./IHappyKoalas.sol";

contract Chummies is ERC721A, OwnableWithAdmin {
    using Strings for uint256;

    uint256 public constant TOTAL_MAX = 4444;

    uint256 public maxPerPublicWallet = 10;
    uint256 public freeMaxTotal = 1200;

    uint256 public publicPrice = 0.007 ether; 

    uint256 freeClaimCount;
    mapping(address => uint256) public addressClaimAmount;

    IHappyKoalas public happyKoalas; // Happy Koalas (AKA Koalaverse: Genesis) holders are guaranteed free mints
    bool[369] public reserveClaimed; // save gas for claimers

    string public baseURI;
    string public baseExtension;

    bool public saleIsActive;
    bool public reserveFunctionRun;
    event SaleStateChanged(bool isActive);

    constructor(address _happyKoalas) ERC721A("Koalaverse: Chummies", "CHUMMIES") {
        happyKoalas = IHappyKoalas(_happyKoalas);
    }

    /* Founder Mint */
    function ownerMint(address _addr, uint256 _qty) external onlyOwnerOrAdmin {
        _mint(_addr, _qty);
    }

    /* Reserve Claim */
    function reserveClaim() external onlyOwnerOrAdmin {
        require(!reserveFunctionRun, "Reserve already claimed");
        for(uint i; i < 41; i++) {
            _mint(address(this), 9);
        }
        reserveFunctionRun = true;
    }
    /*
    * Mint function
    * @notice if you have not claimed a free, subtract .007 ether
    */
    function mintFree(uint256 _quantity) external payable whenSaleIsActive {
        require(totalSupply() < TOTAL_MAX, "Soldout");
        require(freeClaimCount + _quantity < freeMaxTotal, "Sorry, no more freebies available, sorry");
        require(_quantity > 0, "_quantity must be above 0");
        uint256 _addressClaimAmount = addressClaimAmount[msg.sender];
        require(_addressClaimAmount + _quantity <= maxPerPublicWallet, "You are trying to claim more than your allotment");        
        freeClaimCount += _quantity;
        addressClaimAmount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }


    function mint(uint256 _quantity) external payable whenSaleIsActive {
        require(totalSupply() + _quantity <= TOTAL_MAX, "Soldout"); // always first to save users gas if tx fails
        require(_quantity > 0 && _quantity <= maxPerPublicWallet, "_quantity must be above 0 and below max.");
        require(msg.value >= publicPrice * _quantity, "Incorrect amount of ETH");
        _mint(msg.sender, _quantity);
    }

    function claimReserves(uint256[] calldata _tokenIds) external { 
        require(happyKoalas.isOwnerOf(msg.sender, _tokenIds), "Atleast 1 of those ID's is not your token to claim");
        for(uint i; i < _tokenIds.length; i++) {
            require(!reserveClaimed[_tokenIds[i]], "Atleast 1 of those ID's have already been claimed");  
            reserveClaimed[_tokenIds[i]] = true;
            unchecked {
                _addressData[address(this)].balance -= 1;
                _addressData[msg.sender].balance += 1;

                TokenOwnership storage currSlot = _ownerships[_tokenIds[i]];
                currSlot.addr = msg.sender;
                currSlot.startTimestamp = uint64(block.timestamp);

                // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
                // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
                uint256 nextTokenId = _tokenIds[i] + 1;
                TokenOwnership storage nextSlot = _ownerships[nextTokenId];
                if (nextSlot.addr == address(0)) {
                    // This will suffice for checking _exists(nextTokenId),
                    // as a burned slot cannot contain the zero address.
                    if (nextTokenId != _currentIndex) {
                        nextSlot.addr = address(this);
                    }
                }
            }
        emit Transfer(address(this), msg.sender, _tokenIds[i]);
        }
    }

    modifier whenSaleIsActive() {
        require(saleIsActive, "The sale is not active");
        _;
    }

    function setSaleIsActive(bool _intended) external onlyOwnerOrAdmin {
        require(saleIsActive != _intended, "This is already the value");
        saleIsActive = _intended;
        emit SaleStateChanged(_intended);
    }

    /**
     * @notice set base URI
     */
    function setBaseURI(string calldata _baseURI) external onlyOwnerOrAdmin {
        baseURI = _baseURI;
    }

    /**
     * @notice set base extension
     */
    function setBaseExtension(string calldata _baseExtension) external onlyOwnerOrAdmin {
        baseExtension = _baseExtension;
    }

    /**
     * @notice set public sale price in wei
     */
    function setPrice(uint256 _newPrice) external onlyOwnerOrAdmin {
        publicPrice = _newPrice;
    }

    /**
     * @notice set free claim total
     */
    function setFreeMaxTotal(uint256 _newFreeMaxTotal) external onlyOwnerOrAdmin { 
        freeMaxTotal = _newFreeMaxTotal;
    }

    // GETTERS

    function getFreeAmountLeft() external view returns (uint256) {
        return freeMaxTotal - freeClaimCount;
    }
 
    function getAmountClaimedPublic(address _user) external view returns (uint256) {
        return addressClaimAmount[_user];
    }

    /**
     * @notice token URI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), baseExtension));
    }

    address public  founderAddr   =   0xc03f5D2725f1bB7bD599B9FFbA5a16f4A41b459B;
    address public  superdevAddr  =   0x4E9f7618F72F3d497f4e252eBB6a731d715e7af5; //B5
    address public  frontendDev   =   0xB4057C08C729ed8810de0C2a15e74390dD78b09C; //BM
    address public  adminAddr     =   0x07c47A72c65ce8A37622Ea8B15765dAD60163120;
    address public  communityLead =   0x28f0aa00b1659f6a88b0cd8C19230f13bfD932d2;
    address public  tAddr         =   0x32E7709eC2b3346cdf13E07060D4e2DFfd898685; 

    function withdraw() external {
        uint256 balance = address(this).balance;
        sendEth(founderAddr, balance * 36 / 100);
        sendEth(superdevAddr, balance * 30 / 100);
        sendEth(frontendDev, balance * 25 / 100);
        sendEth(adminAddr, balance * 3 / 100);
        sendEth(communityLead, balance * 3 / 100);
        sendEth(tAddr, balance * 3 / 100);
    }

    function sendEth(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }
}