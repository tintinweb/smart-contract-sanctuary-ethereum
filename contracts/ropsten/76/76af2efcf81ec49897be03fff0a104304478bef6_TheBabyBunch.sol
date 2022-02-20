// SPDX-License-Identifier: MIT
// @author: Exotic Technology LTD

/*
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:~77!~!7777!~^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::?55555555555?~~~~~^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!P555?755YY55~.!YYYJ?~^^^^^^~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~?J?Y!~55Y5557JY5YY55Y7^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^?!!777777?JJ?JP5Y55Y555?77~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!?!!??J!~!!7777???5J^?5555J~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!77??777777!!!7?J?7!!7777JY55Y~:^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!77?77777777777777777!!7JJ?7!7?!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!777777777777777777????777777!7J~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!777777777777777777777????????777~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!77777777777777777777777??????????!^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^~77777777777777777777777777?????????~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^7777777777777777777777777777????????7^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^77777777777777JYYJ?7777777777????????~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^77777777777777???JJJ?777777777???????~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^77777777777777~::^!7?777777777???????~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^~7!777?YYJ???~.~^::~777777777???????7~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^~!~!!~:~J!!JJ7^:!!~^^~77!7777????????!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^77~777::^::^^7!::~^:^^7777777??????J?!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^~7!~~!~:.:^~777~:::^^!!7777??????????J!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~7!!!!!!77???77!!!!!!!7????????????7~!7777!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~777777777777777?7777???????J555PGYJ77?JJY!~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!7?????777?????777????JYPB&&&&&&&B5JYY7~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~^^~~!!7?J??????JYYY55PGBBBBB########BJ!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~^7PGGG5PBGGBBBBBGGGBBBB#####BB#B7~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~^YGBJ77YBBBBGPGGGGGBBBB#&###BB#G~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~!5GGP77JBBBGPPGGGGGBB#B#&####&&B!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~77!~J5GGGPPPBBBBP5PGGGGBB##&&&&&&&&&J~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~?!!Y!YPGGGBBB5PBBG5PGGGGBB#&&&&&&###&P7?7~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~?!75!YPGGGBBJ~JY5P55PGGGBB#&&&&&#####577?!~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~7!7Y7?YPGBG?~~!7??JY5GGBBBBGP#&####&&&G??!~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~!~~!J7??JJ!~~~~~~!!7Y5PGBB7~~7PB####BPJ77!~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~7^~^.!!!!~~~~~~~~~~~~?77?JJ~~~~~!777!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~7^^::!~~~~~~~~~~~~~~~!7777!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~!~~!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*/


pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ownable.sol";
import "./ERC721enumerable.sol";
import "./merkle.sol";

contract TheBabyBunch is Ownable, ERC721, ERC721Enumerable {
    
    string public PROVENANCE;
    bool public saleIsActive = false; // false
    
    bytes32 public MerkleRoot = 0x6774ee7e9e9e3d7dc32c54537fbf234425c266412a697974319d0645708d9111;

    uint8 constant public royalty = 44;
    uint16 public  MAX_BABIES;
    uint16 constant public  MAX_PRESALE = 644;

    uint16 constant public MAX_PUBLIC_MINT = 10;

    uint256 constant public babyPresalePrice = 0.05 ether;
    uint256 constant public babyPrice = 0.07 ether;
    

    uint256 public startingIndexBlock = 0;

    uint256 public startingIndex = 0;
    uint256 public SALE_START = 0;

   
    string private _baseURIextended;

    mapping(address => bool) private senders;
    
    
    constructor(uint16 _maxBabies) ERC721("TheBabyBunch", "TBB") {


        require(_maxBabies > 0,"max babies cannot be 0");
       
        MAX_BABIES = _maxBabies;
       
        senders[msg.sender] = true; // add owner to senders list


        _baseURIextended = "ipfs://QmYQt3aL4qDqjbFpvKJ5y6dcpAnRAc6YKjruDns3vVSsyn/0"; //cover baby

    }

    

   function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override  returns (
        address receiver,
        uint256 royaltyAmount
    ){
        require(_exists(_tokenId));
        return (owner(), uint256(royalty * _salePrice / 1000));

    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function emergencySetSaleStart(uint256 _startTime) public onlyOwner {
       // require(SALE_START == 0, "SaleStart already set!");
        require(_startTime > 0, "cannot set to 0!");
        SALE_START = _startTime;
    }

    // set ipfs data to token id sequence by acquiring block number once, and use with MOD MAX_BABIES to set initial index 

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_BABIES;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_BABIES;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex++;
        }
    }

        // @dev launch presale

    function launchPresale(uint16 daysLaunch ) public onlyOwner returns (bool) {
        require(SALE_START == 0, "sale start already set!" );
        require(daysLaunch > 0, "days launch must be positive");
        require(startingIndex != 0, "index must be set to launch presale!");

        SALE_START = block.timestamp + (daysLaunch * 86400);
        saleIsActive = true;
        return true;
    }



    function startSaleSequence(uint16 _days) public onlyOwner {

        require(saleIsActive == false, "Sale already Active!");
     
        setStartingIndex(); // set starting index       
        launchPresale(_days); // launch presale

    }


    function prooveWhitelist(bytes32[] calldata _merkleProof)private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(MerkleProof.verify(_merkleProof, MerkleRoot, leaf));

        return true;
    }
   

    // Sender 
    event AddedToSenders(address indexed account);
    event RemovedFromSenders(address indexed account);

     function addSender(address _address) public onlyOwner  {
        
        require(_address != address(0));
        senders[_address] = true;
        emit AddedToSenders(_address);
    }

    function removeSender(address _address) public onlyOwner {
        require(_address != address(0));
        senders[_address] = false;
        emit RemovedFromSenders(_address);
    }

    function isSender(address _address) public view returns(bool) {
            require(_address != address(0));
            return senders[_address];
    }

    function setMax(uint16 _max) public onlyOwner {
            require(_max >= totalSupply());
            MAX_BABIES = _max;
        }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
            super._beforeTokenTransfer(from, to, tokenId);
        }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
            return super.supportsInterface(interfaceId);
        }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
            _baseURIextended = baseURI_;
        }

    function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
        }

    function setProvenance(string memory provenance) public onlyOwner {
            PROVENANCE = provenance;
        }

    function getSaleState() public view returns (bool) {
            return saleIsActive;
        }



    function _doMint(uint numberOfTokens, address _target)private {
        
            uint256 ts = totalSupply();
            
            for (uint256 i = 0; i < numberOfTokens; i++) {
                _safeMint(_target, ts + i);
            }
        }


    function _confirmMint(uint _numberOfTokens) private view returns (bool) {
        
        uint256 ts = totalSupply();
        
        require(SALE_START != 0);
        require(_numberOfTokens > 0 );
        require(saleIsActive);
        require(_numberOfTokens <= MAX_PUBLIC_MINT);
        require(ts + _numberOfTokens <= MAX_BABIES);
        

        return true;
    }


    function reserve(uint256 n) public onlyOwner {
      
      uint supply = totalSupply();
      require(supply + n <= MAX_BABIES, "Purchase would exceed max tokens");
        
      _doMint(n, _msgSender());
    }


    function mintPresale(uint numberOfTokens, bytes32[] calldata _proof)public payable {
        
        require(block.timestamp < SALE_START, "not presale");
  
        require(prooveWhitelist(_proof),'whitelist');
        require(_confirmMint(numberOfTokens), "number too high");
        require(babyPresalePrice * (numberOfTokens) <= msg.value, "Ether value");

        _doMint(numberOfTokens, _msgSender());
    }


    function mintBaby(uint numberOfTokens) public payable {
        
        require(block.timestamp >= SALE_START, "not yet");
        require(_confirmMint(numberOfTokens));
        require(babyPrice * (numberOfTokens) <= msg.value, "Ether value");
                   
        _doMint(numberOfTokens, _msgSender());
    }

    // senders mint for cc buyers

    function sendCCBaby(address  _target, uint numberOfTokens) public {
        
        require(senders[_msgSender()], "not confirmed to send");
        require(_confirmMint(numberOfTokens));
        

        _doMint(numberOfTokens, _target);
    }


    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        senders[owner()]=false;
        senders[newOwner]=true;
        _transferOwnership(newOwner);

    }
    
}