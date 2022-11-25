// SPDX-License-Identifier: MIT
/*
   _____            _       _    _      ____                      
  / ____|          (_)     | |  | |    |  _ \                     
 | (___  _ __  _ __ _ _ __ | | _| | ___| |_) | ___  _ __ __ _ ___ 
  \___ \| '_ \| '__| | '_ \| |/ / |/ _ \  _ < / _ \| '__/ _` / __|
  ____) | |_) | |  | | | | |   <| |  __/ |_) | (_) | | | (_| \__ \
 |_____/| .__/|_|  |_|_| |_|_|\_\_|\___|____/ \___/|_|  \__, |___/
        | |                                              __/ |    
        |_|                                             |___/     


                                 ::: =,    ;                 
                             ;;=;;===                                      
                ,=YVRMBBMMR=,   :i=                     
              :iVRRMMMMMMBMMM :=;  ==;======
             =tYMMMMMMBBMMM;=Y ,::;==iMMMMMMMMMM     
            ;tYVBBMMVMMMM =; .,,,::;;=YVBBMMMMMMMMM
            ;tYVVYRMMM;=ti ...,,,;::==iMVMMMMMMMMMMMM
            ,=tYRBM;;tVB, ....,  ,::;====YVBMMMMMMMMMM
        ..   ,=t =tYVRB, .....,,,,=:;:;;i=VYMMRMMMMMMMM
       ;;..  ,===iYVVRY .....,,,;,,,,,:;;==t=RBMMMMMMMMM
     :;;:;=;,...       .......,,,,,,,,,:;;==Y=tYMMMMMMMM
    ;.,:,.....         ....,,,,,,,,,,,,,:;;;==YYMRMMMMMM;
    .......             .,,,,,,,,,,,,,,,,::;;;=YtVBMMMMM
  ;t ...                .,,,,,,,,,,,,,,,,,::;;i=RiRMMMMM
  ,=..                    .,,,,,,,,,,,,,,,:::;;=iYBBMM
                           .,,,,,,,,,,,,,,,,::;;;;tVB
          :VMM               .,,,,,,,,,,,,:,,,::;;=
         ,;VBM                 .,,,,,,,,,,,,,:,::
         ,,==                      `,,,,,,,          

              _                          
             | |                         
__      _____| | ___ ___  _ __ ___   ___ 
\ \ /\ / / _ \ |/ __/ _ \| '_ ` _ \ / _ \
 \ V  V /  __/ | (_| (_) | | | | | |  __/
  \_/\_/ \___|_|\___\___/|_| |_| |_|\___|
                                         
 _          _____       _____       _____       _                  
| |        |  __ \     |  __ \     |  __ \     | |                 
| |_ ___   | |  \/ ___ | |  \/ ___ | |  \/ __ _| | __ ___  ___   _ 
| __/ _ \  | | __ / _ \| | __ / _ \| | __ / _` | |/ _` \ \/ / | | |
| || (_) | | |_\ \ (_) | |_\ \ (_) | |_\ \ (_| | | (_| |>  <| |_| |
 \__\___/   \____/\___/ \____/\___/ \____/\__,_|_|\__,_/_/\_\\__, |
                                                              __/ |
                                                             |___/ 
*/



pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";

contract SprinkleBorgs is ERC721A, Ownable {
    bytes32 public merkleRoot;
    uint256 public constant maxSupply = 3000;
    uint256 public price = 0.008 ether;
    uint256 public maxMintAmountPerTx = 1;
    uint256 public minRange = 0;
    uint256 public maxRange = 50;
    uint256 public defaultRange = maxRange;
    string public baseURI = "ipfs://bipbop/";
    bool public whitelistMintEnabled = true;
    bool public paused = true;
    
    mapping(address => bool) public whitelistClaimed;
    mapping(address => uint256) nftPerWallet;

    constructor() ERC721A("SprinkleBorgs", "SPRKLE") {}

    modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= price * _mintAmount, "Insufficient funds!");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function startMint() external onlyOwner {
        paused = false;
    }

    function pauseMint() external onlyOwner {
        paused = true;
    }
    
    function whitelistMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) { 
    // Verify whitelist requirements
    require(whitelistMintEnabled, "Whitelist sale is not enabled!");
    require(!whitelistClaimed[_msgSender()], "Address already claimed!");

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
    }


    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _updatedURI) public onlyOwner {
        baseURI = _updatedURI;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        price = _newCost;
    }


    function setfreeRange(uint256 _newFreeRange) public onlyOwner {
        defaultRange = _newFreeRange;
    }


    function GoGoGoMint(uint256 _mintAmount) public payable {
        require(!paused, "MINT IS PAUSED! BOP!");
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount <= maxSupply, "Mint Exceed Max Supply");
        require(_mintAmount <= maxMintAmountPerTx, "Mint Exceed Max Per Tx");
        if (totalSupply() == maxRange){
                uint256 rangeDifference = defaultRange*2;
                minRange = minRange+rangeDifference;
                maxRange = maxRange+rangeDifference;
            }
        if(!(totalSupply() >= minRange && totalSupply() < maxRange)){
            require(msg.value >= _mintAmount * price, "Bip Bop! You need to send more ETH! Or wait for someone else to mint!");
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner { 
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner { 
        whitelistMintEnabled = _state;
    }
    
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}