// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// BrainToadz NFT https://twitter.com/braintoadznft
// Created by Brain Pasta https://twitter.com/brain_pasta
// Smart contract by Ian Cherkowski https://twitter.com/IanCherkowski

/*
                                   ........ ....                                                    
                              ... .......:^^^^............    ......                                
                         .. .. .:!77??JJJ?JJJJ?!^..........  ...... .....                           
                      ........:!?JJJYYYYJJ?????JJ?77?????77!!!7???7~^^::.... ..                     
                     ....~777??JJ?JYYJJJ???JJJJJJJJJJJJJYYYYYJJJJJJJJYJJ?77!~:...                   
                     .. ~JJYYYJ??JJJJJ???JJYYYYJJ?J?JJYYYJJJJ?JJJYYYYYYYYJJJJ?. ..                  
                    .. .?JJYJJJJJJ???JJJJYYYJJJJJJ?JJYYJJ??????JJYJJJJJJJJJJJJ~.. ..                
                 ... .:7J??JJJYYYJ??J?JYYYJJ??????JJJJJ???JJJJJ??J???J????????J?!~....              
                ....^7?J?JJYYYJJJJJJJJJJJJJJJJJJJJ?J??JJJJYYYYYJJJJJJJJ?JJJJJJJJJJ7....             
                ...:JJJJJYYJJJYYYYYYJJJJJJYYYYYJJJJJJ?JJJJJJJJYYYJJJJJJ?JJYYYYYYYJ!...              
                ...:?JJJYJJJJJJJJ?777???JJJJ?!~^~~!??JJJJJ???77!!!7??JJJ?JJJJJJ?7:...               
                 .. ^7~^^~~~~~^^:.. ...:^~~^.  ..  .::^^^:::..     .:~!?JJJJJ?7:. ..                
                 ..... ..........:^^^::......:^~~^^:........::^^^^^:.  .:^^^::. ....                
                  ....^~~~~~~~~~~!!!!!!!~~~~~!!!!!!!!~~~~~~~!!!!!!!!~^::......:^....                
                  ...^!!!!!!!!!!!!!7777777!!!!77777777777777777777!!!!!!~~~~~!!!^ ..                
                  ...^!77777777777777777777777777777777777777777777777777!!!77!!~....               
                 ....^~77777777777777777777777777777777!!~^^:::::^^~~!777777777!!: ..               
          .......... ..:~77777777777777777777777777777~..            ..^!777777!!~....              
        .. :JYYY5P5Y?~. .:!7777777777777777777777777!^.  .^!!777!JY?!:  .^77777!!!:...              
       .. !GGGGGGGGGGGY:  :!7777777777777777777777!:.  ^JPGGGBBBBGGGGP!.. ^77777!!^ ..              
      .. !GGGGPJ??5GGGG5:. :777777777777777777777!: ..?GGGGG57!!?PGGGGG~ ..!7777!!~....             
     ...:PGGGP:.Y~.5GGGGY.. ~77777777777777777777~ . 7BGGGGG~ ~~ ~GGGGGY.. ^77777!~....             
     .. ^GGGGP~:7:!GGGGGG:. ^77777777777777777777!...^PGGGGG57~~75GGGGGY.. ^77777!!:...             
     ....JGGGGG5J5GGGGGGY.. ~777777777777777777777~.  :JPGGGGGGGGGGGGGP^...!77777!!: ..             
      ....~?YPGGBGGGGGP?.  :77777777777777777777777!:.  .~?YPGGGGGGPY7:  .~777777!!: ..             
        ... ..^~7???!^. ..~77777777777777777777777777!^:.   .:^~~~^..  .^!7777777!!^ ..             
             ... .   .:^~7777777777777777777777777777777!~^::.......:^~!777777777!!^....            
                  ...~7777777777777777777777777777777777777777!!!!!77777777777777!!~....            
                  ...~777777777777777777777777777777777777777777777777777777777777!~....            
                  ...~!77777777777777777777777777777777777777777777777777777777777!!:...            
                  ...~!!7777777777777777777777777777777777777777777777777777777777!!: ..            
                  ...^!~!777777777777777777777777777777777777777777777777777777777!!^....           
                  .. :!~!7777777777777777777777777777777777777777777777777777777777!~....           
                  ....~!!777777777777777777777777777777!!!!!!!!!!!!!!!!777777777777!~....           
                   .. :!!7777!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~!!!!777777!~....           
                    ...!!!!~~~~~~^^^^^^^^^::::::::.........................::^~!!!7!~....           
                   ....:........          ........:::::^^^^^^^^~~~~~~~^^^::.  .:^~!!~....           
              ..........:::^^^^~~!!!!!77777???????JJJJJJJJJJJJJJJJJJJJJJJJ??7~. .:~!~....           
            ....^~~~!!!!!777777????????777!!!!!!!!!!!!~~~^^::::~?JJJJJJJJJJJJJ~ ..~!~....           
            .............................................:::::^!JJJJJJJJJ???7~.  :!!^...            
             ....:~77??7777??777!!!!!!!777???????????????JJJJJJ???777!~^^:..  ..^!!!:...            
               .....^~!7?????JJJJJJJJJJJJJJ???????7777!!~~^^^::....     ...:^~!777!~....            
                   .. .....::::::^^^^^:::::::......        .....:::^^~~!!!7777777!~:...             
                          ....................::::^^^^~~~~!!!!777777777777777777!!:...              
                          ....~!!!!!!!!!77777777777777777777777777777777777777!!~:....              
                           ....~!!!7777777777777777777777777777777777777777!!!~^. ......            
                            ....^~!!!!!7777777777777777777777777777777777!!!~~: ..^!^....           
                             .....::^~~~!!!!!!777777777777!!!!!!!!!!!!!!~~^:......~!!^....          
                                ........::^~~~~!!!!!!!!!!!~~~~~~~^^^:::.......  ...^!!~.....        
                                     ..........:::^^^::::.................       .. ^!!~....        
                                           ....................                   ...^!!~....       
                                                                                  ....~!!: ...      
                                                                                   .. :!!~....      
                                                                                   ....!!~....      
*/

// The toads came crawling out of my pasta during the hysteria of the bull, they heard everyone 
// screaming “WAGMI” and “ITS GOING TO THE MOON” and they got excited because they smelled bullshit. 
// With bullshit comes flies and toads LOVE to eat flies.

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

contract BrainToadz is
    ERC721A,
    ReentrancyGuard,
    Ownable,
    ERC2981
{

    bool public presaleOpen = false;
    bool public publicOpen = false;
    bool public freezeURI = false;
    bool public reveal = false;
    string private constant _name = "BRAINTOADZ";
    string private constant _symbol = "TOADZ";
    string public baseURI = "ipfs://QmRHxxupHAhDNxBGYQK66G8oe9yrTH6SBsCauQVwukdbtU";
    uint16 public maxSupply = 3333;
    uint16 public maxMint = 5;
    uint256 public preCost = 0.069 ether;
    uint256 public saleCost = 0.0777 ether;
    bytes32 private whitelistMerkleRoot;
	mapping(address => uint16) private minted;

    event PaymentReceived(address from, uint256 amount);

    constructor() ERC721A(_name, _symbol) payable {
        _setDefaultRoyalty(0xf77A1008f32BC46403C80991E2F590888f750cE5, 500);
    }

    //enable payments to be received from airdrops
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    // @dev public minting
	function mint(uint16 mintAmount, bytes32[] calldata merkleProof) external payable nonReentrant {
        bool approved;

        require(Address.isContract(msg.sender) == false, "I don't want to make promises");
        require(totalSupply() + mintAmount <= maxSupply, "Rock on");

        if (msg.sender == owner()) {
            //unrestricted for owner

        } else if (presaleOpen && !publicOpen) {
            approved = isValidMerkleProof(msg.sender, merkleProof);
            require(approved, "BRAINTOAD likes triangles man");
            require(mintAmount + minted[msg.sender] <= maxMint, "I want to do live events");
            require(msg.value >= preCost * mintAmount, "I want to do creator accelerator");

        } else if (publicOpen) {
            require(mintAmount + minted[msg.sender] <= maxMint, "Im obviously creating a clothing brand");
            require(msg.value >= saleCost * mintAmount, "We are stronger together");

        } else {
            require(false, "Soon the NFT market was filled with Amphibians");
        }
        
        minted[msg.sender] += mintAmount;
        _safeMint(msg.sender, mintAmount);
	}

    // @dev to check presale address list
    function isValidMerkleProof(address to, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(to)));
    }

    // @dev to set presale root value
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    // @dev max mint amount for paid nft
    function setMaxMint(uint16 _newMax) external onlyOwner {
	    maxMint = _newMax;
	}

    // @dev set cost of minting
	function setSaleCost(uint256 _newCost) external onlyOwner {
    	saleCost = _newCost;
	}
			
    // @dev set cost of minting
	function setPreCost(uint256 _newCost) external onlyOwner {
    	preCost = _newCost;
	}

    // @dev cost of presale or main sale
    function cost() external view returns (uint256) {
        uint256 mintCost;
        if (publicOpen) {
            mintCost = saleCost;
        } else {
            mintCost = preCost;
        }
        return mintCost;
    }

    // @dev open main sales to allow anyone to mint
	function setPublicOpen(bool _status) external onlyOwner {
    	publicOpen = _status;
	}

    // @dev presale allows only approved list to mint
	function setPresaleOpen(bool _status) external onlyOwner {
    	presaleOpen = _status;
	}

    // @dev Set the base url path to the metadata and the reveal flag
    function setBaseURI(string memory _baseTokenURI, bool setReveal) external onlyOwner {
        require(freezeURI == false, "wen");
        baseURI = _baseTokenURI;
        reveal = setReveal;
    }

    // @dev freeze the URI
    function setFreezeURI() external onlyOwner {
        freezeURI = true;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev show the uri for preveal or revealed json
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        //string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0
                ? reveal
                    ?
                    string(abi.encodePacked(baseURI, _toString(tokenId),".json"))
                    : baseURI
                : '';
    }

    // @dev reduce max supply if needed
    function reduceMaxSupply(uint16 newMax) external onlyOwner {
        require(newMax < maxSupply, "Bring glitched cartoons back");
        require(newMax >= totalSupply(), "Ranch ranch yall");
        maxSupply = newMax;
    }

    // @dev to support royalties
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // @dev ask for royalties
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // @dev allow withdraw of eth
    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    // @dev allow withdraw of erc20
    function withdrawToken(IERC20 token) external onlyOwner {
        SafeERC20.safeTransfer(token, payable(owner()), token.balanceOf(address(this)));
    }
}