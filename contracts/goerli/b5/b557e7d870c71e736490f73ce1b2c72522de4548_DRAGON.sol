// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Whitelist.sol";
import "./ERC721.sol";
import "./IERC721.sol";


contract DRAGON is ERC721Enumerable, ReentrancyGuard, Ownable, Whitelist  {

    string public baseTokenURI = "ipfs://bafybeicqzib7qayi3egdqjrg5ivqtibkutnjul57zsuls63dcieyulwxmm/";

    uint256 public constant MAX_DRAGON = 7777;
    uint256 public namingAngelPrice = 0.002 ether;
    uint256 public mintPrice = 0.001 ether;
    uint256 public whiteListMintPrice = 0 ether;



    uint256 public maxMintAmount = 200;
    uint256 public maxWLMintAmount = 1;


    bool public mintIsActive = true;
    bool public whiteListMintIsActive = true;


    mapping(uint256 => string) public nameAngel;
    mapping(address => uint256) public balanceAngel;


    event NameChanged(string name);

    constructor() ERC721("Dragon", "Dragon") {
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMaxMintAmount(uint256 _amount) external onlyOwner {
        maxMintAmount = _amount;
    }

    function setMaxWLMintAmount(uint256 _amount) external onlyOwner {
        maxWLMintAmount = _amount;
    }

    function setBalanceAngel(address wallet, uint256 _newBalance) external onlyOwner {
        balanceAngel[wallet] = _newBalance;
    }

    function setNamingPrice(uint256 _namingPrice) external onlyOwner {
        namingAngelPrice = _namingPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        payable(msg.sender).transfer(balance);
    }

  /**
    * @dev Allow contract owner to withdraw ERC-20 balance from contract
    * while still splitting royalty payments to all other team members.
    * in the event ERC-20 tokens are paid to the contract.
    * @param _tokenContract contract of ERC-20 token to withdraw
    * @param _amount balance to withdraw according to balanceOf of ERC-20 token
    */
  function withdrawAllERC20(address _tokenContract, uint256 _amount) public onlyOwner {
    require(_amount > 0);
    IERC20 tokenContract = IERC20(_tokenContract);
    require(tokenContract.balanceOf(address(this)) >= _amount, 'Contract does not own enough tokens');
    tokenContract.transfer(msg.sender, _amount );
  }

    function setMintActive() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function setWLMintActive() public onlyOwner {
        whiteListMintIsActive = !whiteListMintIsActive;
    }

    function mintAdmin(uint256[] calldata tokenIds, address _to) public payable onlyOwner {
        require(totalSupply() + tokenIds.length <= MAX_DRAGON, "Minting would exceed max supply of Angels");

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] < MAX_DRAGON, "Invalid token ID");
            require(!_exists(tokenIds[i]), "Tokens has already been minted");

            if (totalSupply() < MAX_DRAGON) {
                _safeMint(_to, tokenIds[i]);
                balanceAngel[_to] += 1;
            }
        }
    }

    function mint(uint256 _amount) public payable nonReentrant {
        require(mintIsActive, "Mint is closed");
        require(totalSupply() + _amount <= MAX_DRAGON, "Minting would exceed max supply of Angels");
        require(balanceOf(msg.sender) + _amount<=maxMintAmount, "Wallet address is over the maximum allowed mints");
        require(msg.value == mintPrice*_amount, "Value needs to be exactly the reward fee!");

        for(uint256 i = 0; i < _amount; i++) {
            if (totalSupply() < MAX_DRAGON) {
                _safeMint(msg.sender,totalSupply()+1);
                balanceAngel[msg.sender] += 1;
            }
        }
    }


    function mintToWhiteList(address _to,uint256 _amount, bytes32[] calldata _merkleProof) public payable nonReentrant {
        require(whiteListMintIsActive, "Whitelist minting is closed");
        require(isWhitelisted(_to, _merkleProof), "Address is not in Allowlist!");
        require(totalSupply() + _amount <= MAX_DRAGON, "Minting would exceed max supply of Angels");
        require(balanceOf(msg.sender) + _amount<=maxWLMintAmount, "Wallet address is over the maximum allowed mints");
        require(msg.value == whiteListMintPrice*_amount, "Value needs to be exactly the reward fee!");
        
        for(uint256 i = 0; i < _amount; i++) {
            if (totalSupply() < MAX_DRAGON) {
                _safeMint(msg.sender,totalSupply()+1);
                balanceAngel[msg.sender] += 1;
            }
        }
        }

    function transferFrom(address from, address to, uint256 tokenId) public override nonReentrant {
        balanceAngel[from] -= 1;
        balanceAngel[to] += 1;

        ERC721.transferFrom(from, to, tokenId);
    }



    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override nonReentrant {
        balanceAngel[from] -= 1;
        balanceAngel[to] += 1;

        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    function changeName(uint256 _tokenId, string memory _newName) public {
        require(ownerOf(_tokenId) == msg.sender);
        require(validateName(_newName) == true, "Invalid name");
        
        //can not set the same name
        for (uint256 i; i < totalSupply(); i++) {
            if (bytes(nameAngel[i]).length != bytes(_newName).length) {
                continue;
        } else {
            require(keccak256(abi.encode(nameAngel[i])) != keccak256(abi.encode(_newName)), "name is used");
        }
        }

        nameAngel[_tokenId] = _newName;

        emit NameChanged(_newName);
    }

    function validateName(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);

        if(b.length < 1) return false;
        if(b.length > 15) return false;
        if(b[0] == 0x20) return false; // Leading space
        if(b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];


        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A)  //A-Z
            ) {
                return false;
            }

            lastChar = char;
        }

        return true;
    }
}