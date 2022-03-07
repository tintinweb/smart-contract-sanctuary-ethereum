// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// March 6th, 2022
// https://slamjokers.com
// Made for "Jokers by SLAM" by @Kadabra_SLAM (Telegram)

/*

    Static is boring. Introducing, Dynamic NFTs!

    "Dynamic Non-Fungible Tokens (dNFTs) are the next stage in the evolution of the NFT space,
    combining the verifiably unique nature of NFTs with dynamic data inputs and off-chain computation."

    We are happy to be one of pioneers in the dNFTs world. 
    - Abra & Kadabra

     ___         _                         _                 _____  _      ___  ___  ___
    |_  |       | |                       | |              /  ___|| |     / _ \ |  \/  |
        | |  ___  | | __ ___  _ __  ___   | |__   _   _    \ `--. | |    / /_\ \| .  . |
        | | / _ \ | |/ // _ \| '__|/ __|  | '_ \ | | | |    `--. \| |    |  _  || |\/| |
    /\__/ /| (_) ||   <|  __/| |   \__ \  | |_) || |_| |   /\__/ /| |____| | | || |  | |
    \____/  \___/ |_|\_\\___||_|   |___/  |_.__/  \__, |   \____/ \_____/\_| |_/\_|  |_/
                                                   __/ |                              
                                                  |___/                               

    S/O to the Azuki team for creating such an elegant library: ERC721A
*/

import "libraries.sol";

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract JokersBySLAM is ERC721A, Ownable, ReentrancyGuard {
    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;
    string public baseURI = "https://api.slamjokers.com/joker/";
    address private _signer;
    uint256 public claimedReserved;
    uint256 public immutable maxPerMint = 10;
    uint256 public immutable collectionSize = 8888;
    uint256 public reserveAmount;
    uint256 public discountAmountPerJoker = 0.0014 ether;
    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event SignerChanged(address signer);
    event ReservedTokenMinted(address minter, address recipient, uint256 amount);
    event BaseURIChanged(string newBaseURI);
    event ReserveAmountChanged(uint256 newReservedAmount);

    constructor(
        address signer,
        uint256 _reserveAmount
    ) ERC721A("Jokers by SLAM", "JOKERS") {
        _signer = signer;
        reserveAmount = _reserveAmount;
    }

    function bulkMint(address[] calldata recipients, uint256 each_amount, bool reserved) external nonReentrant onlyOwner {
        //to mint in behalf of team, designers, raffle winners, bsc/polygon sales, giveaway winners, slam billionaires
        require(each_amount > 0, "Jokers: invalid amount");
        require(recipients.length > 0, "Jokers: invalid amount");

        uint256 amount = recipients.length * each_amount;
        require(totalSupply() + amount <= collectionSize, "Jokers: max supply exceeded");

        if(reserved){
            require(claimedReserved + amount <= reserveAmount, "Jokers: max reserve amount exceeded");
        }

        for (uint256 i = 0; i < recipients.length; i++){
            _safeMint(recipients[i], each_amount);
        }
        
        if(reserved){
            claimedReserved += amount;
        }
    }

    function VerifyMessage(string memory sign_name, bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) private view {
        require(keccak256(abi.encode(sign_name, msg.sender)) == _hashedMessage, "This hash is not valid for msg.sender");

        //get signer
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        require(_signer == ecrecover(prefixedHashMessage, _v, _r, _s), "Not signed by the official signer.");
    }

    function presaleMint(uint256 amount, bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) external nonReentrant payable {
        require(status == Status.PreSale, "Jokers: Presale is not active.");
        
        VerifyMessage("presale", _hashedMessage, _v, _r, _s);

        require(amount <= maxPerMint, "Jokers: Max per mint amount per transaction exceeded.");
        require(totalSupply() + amount + reserveAmount - claimedReserved <= collectionSize, "Jokers: Max supply exceeded.");
        uint256 totalCost = getJokerPrice(0.06 ether, amount);
        _safeMint(msg.sender, amount);
        refundIfOver(totalCost);
        emit Minted(msg.sender, amount);
    }

    function mint(uint256 amount) external nonReentrant payable {
        require(status == Status.PublicSale, "Jokers: Public sale is not active.");

        require(amount <= maxPerMint, "Jokers: Max per mint amount per transaction exceeded.");
        require(totalSupply() + amount + reserveAmount - claimedReserved <= collectionSize, "Jokers: Max supply exceeded.");
        uint256 totalCost = getJokerPrice(0.07 ether, amount);
        _safeMint(msg.sender, amount);
        refundIfOver(totalCost);
        emit Minted(msg.sender, amount);
    }

    function getJokerPrice(uint256 price, uint256 _quantity) internal view returns (uint256){
        require(_quantity > 0, "Must be greater than zero");

        return (price * _quantity) - ((_quantity - 1) * discountAmountPerJoker);
    }

    function setdiscountAmount(uint256 _discountAmountPerJoker) external onlyOwner {
        discountAmountPerJoker = _discountAmountPerJoker;
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setReservedAmount(uint256 _newReservedAmount) external onlyOwner {
        reserveAmount = _newReservedAmount;
        emit ReserveAmountChanged(_newReservedAmount);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
        emit SignerChanged(signer);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Jokers: Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdraw() external nonReentrant onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // To get any tokens out of the contract if needed
    function withdrawNFT(address _nftTokenContract, address _to) external nonReentrant onlyOwner{
        IERC721 nftTokenContract = IERC721(_nftTokenContract);
        nftTokenContract.setApprovalForAll(_to, true);
    }

    function withdrawToken(address _tokenContract, uint256 _amount, address _to) external nonReentrant onlyOwner{
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(_to, _amount);
    }

    function withdrawToken_All(address _tokenContract, address _to) external nonReentrant onlyOwner{
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 _amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(_to, _amount);
    }
}