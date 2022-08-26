//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 < 0.9.0;

 
import "./Strings.sol";
import "./ERC721A.sol";
import "./Context.sol";


contract Wool is ERC721A, Context {

 
    using Strings for uint256;

    event StageChanged(Stage from, Stage to);

    enum Stage {
        Pause,
        Free,
        Public
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "Wool: not owner");
        _;
    }

    uint256 public constant MAX_SUPPLY = 666;
    uint256 public freeSupply = 500;
    uint256 public saveSupply = 66;
    uint256 public price = 0.001 ether;
    uint256 public constant MAX_MINT_PER_WALLET_FREE = 8;
    address public immutable owner;

    //whitelistAddress
    mapping(address => bool) public whitelistAddress;
    //has address Minted  num
    mapping(address => uint256) public addressMinted;

 
 

    Stage public stage;
    string public baseURI;
    string internal baseExtension = ".json";

    constructor() ERC721A("Wool", "Wool") {
        owner = _msgSender();
       // _safeMint(msg.sender, saveSupply);
    }

    // GET Functions
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Wool: not exist");
        string memory currentBaseURI = _baseURI();
        return (
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : ""
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    // MINT Functions
    // Only works before freeSupply is reached
    // This function only work once
 

    function mint(uint256 num) external payable {
        uint256 currentSupply = totalSupply();
        require(num > 0 ,"Wool: mint num need > 0 ." );
        require(currentSupply + num <= MAX_SUPPLY, "Wool: exceed max supply." );
        require(addressMinted[msg.sender] + num <= MAX_MINT_PER_WALLET_FREE,  "Wool: has minted max num." );


        if (stage == Stage.Free) {
            require(whitelistAddress[msg.sender] == true, "Wool: not in  whitelist list.");
            require(currentSupply + num - saveSupply <= freeSupply, "Wool: free mint max supply.");
        } else if (stage == Stage.Public) {
            require(currentSupply + num <= MAX_SUPPLY,"Wool: free mint max supply.");
            require(msg.value >= price * num,  "Wool: insufficient fund.");
        } else {
            revert("Wool: mint is pause.");
        }

        addressMinted[msg.sender] =  addressMinted[msg.sender] + num;
        _safeMint(msg.sender, num);
    }


    // SET Functions
    function setStage(Stage newStage) external onlyOwner {
        require(stage != newStage, "Wool: invalid stage.");
        Stage prevStage = stage;
        stage = newStage;
        emit StageChanged(prevStage, stage);
    }

    function setFreeSupply(uint256 newFreeSupply) external onlyOwner {
        freeSupply = newFreeSupply;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    //add white address
    function addWhitelistaddress(address _addresss) external onlyOwner {
       whitelistAddress[_addresss] = true;
    }

    //delet white address
    function delWhitelistaddress(address _addresss) external onlyOwner {
       whitelistAddress[_addresss] = false;
    }


    // WITHDRAW Functions
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No money");
        _withdraw(msg.sender, address(this).balance);
    }
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}