// SPDX-License-Identifier: MIT

//          _____                    _____                    _____                            _____                    _____                    _____                    _____                    _____          
//         /\    \                  /\    \                  /\    \                          /\    \                  /\    \                  /\    \                  /\    \                  /\    \         
//        /::\    \                /::\____\                /::\    \                        /::\    \                /::\    \                /::\    \                /::\____\                /::\    \        
//       /::::\    \              /:::/    /               /::::\    \                      /::::\    \              /::::\    \              /::::\    \              /::::|   |               /::::\    \       
//      /::::::\    \            /:::/    /               /::::::\    \                    /::::::\    \            /::::::\    \            /::::::\    \            /:::::|   |              /::::::\    \      
//     /:::/\:::\    \          /:::/    /               /:::/\:::\    \                  /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \          /::::::|   |             /:::/\:::\    \     
//    /:::/__\:::\    \        /:::/    /               /:::/  \:::\    \                /:::/__\:::\    \        /:::/__\:::\    \        /:::/__\:::\    \        /:::/|::|   |            /:::/__\:::\    \    
//   /::::\   \:::\    \      /:::/    /               /:::/    \:::\    \              /::::\   \:::\    \      /::::\   \:::\    \      /::::\   \:::\    \      /:::/ |::|   |            \:::\   \:::\    \   
//  /::::::\   \:::\    \    /:::/    /      _____    /:::/    / \:::\    \            /::::::\   \:::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/  |::|   | _____    ___\:::\   \:::\    \  
// /:::/\:::\   \:::\    \  /:::/____/      /\    \  /:::/    /   \:::\ ___\          /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\  /:::/\:::\   \:::\    \  /:::/   |::|   |/\    \  /\   \:::\   \:::\    \ 
///:::/  \:::\   \:::\____\|:::|    /      /::\____\/:::/____/     \:::|    |        /:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |/:::/__\:::\   \:::\____\/:: /    |::|   /::\____\/::\   \:::\   \:::\____\
//\::/    \:::\   \::/    /|:::|____\     /:::/    /\:::\    \     /:::|____|        \::/    \:::\   \::/    /\::/   |::::\  /:::|____|\:::\   \:::\   \::/    /\::/    /|::|  /:::/    /\:::\   \:::\   \::/    /
// \/____/ \:::\   \/____/  \:::\    \   /:::/    /  \:::\    \   /:::/    /          \/____/ \:::\   \/____/  \/____|:::::\/:::/    /  \:::\   \:::\   \/____/  \/____/ |::| /:::/    /  \:::\   \:::\   \/____/ 
//          \:::\    \       \:::\    \ /:::/    /    \:::\    \ /:::/    /                    \:::\    \            |:::::::::/    /    \:::\   \:::\    \              |::|/:::/    /    \:::\   \:::\    \     
//           \:::\____\       \:::\    /:::/    /      \:::\    /:::/    /                      \:::\____\           |::|\::::/    /      \:::\   \:::\____\             |::::::/    /      \:::\   \:::\____\    
//            \::/    /        \:::\__/:::/    /        \:::\  /:::/    /                        \::/    /           |::| \::/____/        \:::\   \::/    /             |:::::/    /        \:::\  /:::/    /    
//             \/____/          \::::::::/    /          \:::\/:::/    /                          \/____/            |::|  ~|               \:::\   \/____/              |::::/    /          \:::\/:::/    /     
//                               \::::::/    /            \::::::/    /                                              |::|   |                \:::\    \                  /:::/    /            \::::::/    /      
//                                \::::/    /              \::::/    /                                               \::|   |                 \:::\____\                /:::/    /              \::::/    /       
//                                 \::/____/                \::/____/                                                 \:|   |                  \::/    /                \::/    /                \::/    /        
//                                  ~~                       ~~                                                        \|___|                   \/____/                  \/____/                  \/____/         

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";


interface IFud {
    function mint(address to, uint256 value) external;
    function burn(address user, uint256 amount) external;
}

contract FudBuds is Ownable, ERC721A {
  
  IFud public Fud;

  uint256 public immutable maxPerAddress;
  
  uint256 public maxFreePerTransaction = 3;

  uint256 public maxPerTransaction = 20; 

  uint256 public mintPrice = 0.035 ether;

  bool public mintActive = false;
  
  bool public claimingActive = false;

  string private _baseTokenURI;

  uint256 public maxFreeSupply = 1000;

  uint256 public maxGenesis = 3333;

  uint256 public startTime;

  mapping(address => uint256) public lastTimeClaimed;
  mapping(address => uint256) public fudFrensBalance;
  mapping(address => uint256) public outstandingFud;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) ERC721A("Fud Frens", "FF", maxBatchSize_, collectionSize_) {
    maxPerAddress = maxBatchSize_;
    startTime = block.timestamp;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function freeMint(uint256 quantity) external callerIsUser {
    require(mintActive, "mint is not active");
    require(totalSupply() + quantity <= maxFreeSupply, "max supply has been reached");
    require(quantity <= maxFreePerTransaction, "max 3 per transaction");
    fudFrensBalance[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function mint(uint256 quantity) external payable callerIsUser {
    require(mintActive, "mint is not active");
    require(totalSupply() + quantity <= maxGenesis, "max supply has been reached");
    require( quantity <= maxPerTransaction, "max 20 per address");
    require(msg.value >= mintPrice * quantity, "not enough eth sent");
    fudFrensBalance[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function devMint(uint256 quantity) external onlyOwner {
    require(quantity % maxBatchSize == 0,"can only mint a multiple of the maxBatchSize");
    require(totalSupply() + quantity <= maxGenesis, "max supply has been reached");
    uint256 numChunks = quantity / maxBatchSize;
    fudFrensBalance[msg.sender] += quantity; 
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  //This will also claim any outstanding Fud
  function mintWithFud() external callerIsUser {
    require(totalSupply() < collectionSize, "max supply has been reached");
    Fud.burn(msg.sender, 60 ether);
    outstandingFud[msg.sender] += getOwedFud(msg.sender);
    lastTimeClaimed[msg.sender] = block.timestamp;
    _safeMint(msg.sender, 1);
  }

  function claimFud() external {
    Fud.mint(msg.sender, getOwedFud(msg.sender) + outstandingFud[msg.sender]);
    lastTimeClaimed[msg.sender] = block.timestamp;
    outstandingFud[msg.sender] = 0;
  }

  function getOwedFud(address user) public view returns(uint256) {
    return((block.timestamp - (lastTimeClaimed[user] >= startTime ? lastTimeClaimed[user] : startTime)) * fudFrensBalance[user] * 1 ether / 1 days);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function toggleClaimingActive() public onlyOwner {
    claimingActive = !claimingActive;
  }

  function withdrawMoney() external onlyOwner {
    require(address(this).balance > 0);
    payable(msg.sender).transfer(address(this).balance);
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner {
    _setOwnersExplicit(quantity);
  }

  function toggleMintActive() external onlyOwner {
    mintActive = !mintActive;
  }

  function setFudAddress(address _fudAddress) external onlyOwner {
    Fud = IFud(_fudAddress);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function updateOwedFud(address from, address to) internal {
        require(msg.sender == address(this));
        if(from != address(0)){
            outstandingFud[from] += getOwedFud(from);
            lastTimeClaimed[from] = block.timestamp;
        }
        if(to != address(0)){
            outstandingFud[to] += getOwedFud(to);
            lastTimeClaimed[to] = block.timestamp;
        }
    }

  function transferFrom(address from, address to, uint256 tokenId) public override {
    updateOwedFud(from, to);
    fudFrensBalance[from]--;
    fudFrensBalance[to]++;
    
    ERC721A.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
    updateOwedFud(from, to);
    fudFrensBalance[from]--;
    fudFrensBalance[to]++;

    ERC721A.safeTransferFrom(from, to, tokenId, data);
  }

}