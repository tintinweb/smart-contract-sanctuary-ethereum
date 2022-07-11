// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/*
MNK0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000KNM
MO'..   ................................   .... ..... ..  ...  ................................. 'kM
Mk.                                           ......,;;,'.                                       .kM
Mk.                                     .;ldk0KXXXXNWMWWNKOdc,.                                  .kM
Mk.                                 .;oOXWMMMMMMMMMMMMMMMMMMMWKx:.                               .kM
Mk.                             .,lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:.                            .kM
Mk.                          'lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd'                          .kM
Mk.                        .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'                        .kM
Mk.                        lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0,                       .kM
Mk.                       ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'                      .kM
Mk.                      .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.                     .kM
Mk.                      ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                     .kM
Mk.                     .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                     .kM
Mk.                     ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                     .kM
Mk.                     oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                     .kM
Mk.                    .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                     .kM
Mk.                    .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                     .kM
Mk.                    .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,                     .kM
Mk.                    ,KMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                     .kM
Mk.                    lNMMMMMMM0l:;;;:lx0XWMMMMMMMMMMMMWMMMUNLEARNkNMMMMMNl                     .kM
Mk.                   .xMMMMMMMWl        ..:d0NMMMMMMNOo:'.        ,KMMMMMNc                     .kM
Mk.                    oWMMMMMMMk.           .;0MMMMK:             :XMMMMMK,                     .kM
Mk.                    '0MMMMMMMWk:..     ..';oKMMMMNxc,...     ..:0WMMMMWx.                     .kM
Mk.                     cXMMMMMMMMWXK0OOO00KNWMMMMMMMMMWXK00OOOO0XWMMMMMMX:                      .kM
Mk.                     .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                      .kM
Mk.                      .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                       .kM
Mk.                       :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;                       .kM
Mk.                       .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                       .kM
Mk.                        ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                        .kM
Mk.                         oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                        .kM
Mk.                         .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,                         .kM
Mk.                          '0MMMMMMMMMMMMMMWNK0000KKNWMMMMMMMMMMMMMXc                          .kM
Mk.                           lWMMMMMMMMMMW0l,...  ....;dXMMMMMMMMMMWd.                          .kM
Mk.                           ,KMMMMMMMMMMX;            .xMMMMMMMMMMNl                           .kM
Mk.                          .dNMMMMMMMMMMNl            ;0MMMMMMMMMMWo                           .kM
Mk.                         ;0WMMMMMMMMMMMMXd,.       'oKMMMMMMMMMMMWk.                          .kM
Mk.                       .lXMMMMMMMMMMMMMMMMN0xooooxOXWMMMMMMMMMMMMMW0l'                        .kM
Mk.                      ,kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx;                      .kM
Mk.                    .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.                    .kM
Mk.                    ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                    .kM
Mk.                    .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                    .kM
Mk.                     ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.                    .kM
Mk.                      :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.                     .kM
Mk.                       ;ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;                       .kM
Mk.                        .;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.                        .kM
Mk.                           .:xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0o,                           .kM
Mk.                              .;ok0NWMMMMMMMMMMMMMMMMMMMMMWXOxc'.                             .kM
Mk.                                  ..;cldxkO0KKKKKK00Okxol:,.                                  .kM
MKocccccccccccccccccccccccccccccccccccccccccloodddddddollccccccccccccccccccccccccccccccccccccccccoKM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

// Everybody be cool! This is a robbery! https://twitter.com/BandOfCrazy
// Smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

contract BandOfCrazy is
    ERC721A,
    ReentrancyGuard,
    Ownable,
    ERC2981
{
    event PaymentReceived(address from, uint256 amount);

    struct Character {
        string name;
        uint16 supply;
        uint16 minted;
        uint16 lower;
        uint16 upper;
        uint256 cost;
        uint256 discount;
    }
    Character[] public characters; // store a list of character

    struct Tool {
        string name;
        uint16 count;
        uint16 ability;
        uint256 cost;
        uint256 tokens;
    }
    Tool[] public tools; // store a list of tools

    string private constant _name = "Band Of Crazy Proper Criminals";
    string private constant _symbol = "BOC";
    string public baseURI = "https://ipfs.io/ipfs/QmPnbNRjn4bSL7rsuiX8hAvkwd8CKjB7jZYzcvRXNuDTWk/";
    uint16 public maxMint = 3;
    uint16 public maxSupply = 7777;
    uint16 public irlalpha = 100;
    uint16[] public ability = [0]; //id starts at 1
    uint16[] public character = [0]; //id starts at 1
    bool[6] public phaseActive;
    bytes32 public whitelistMerkleRoot;
	mapping(address => uint16) public minted;
    mapping(uint16 => uint16) public left;
    mapping(uint16 => uint16) public right;
    mapping(uint16 => bool) public jailed;
    address public jailer = msg.sender;

    IERC20 public stakingToken20 = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);

    constructor() ERC721A(_name, _symbol) payable {
        _setDefaultRoyalty(address(this), 500);
        tools.push(Tool("empty", 0, 1, 2, 3)); //0 tool is skipped
        characters.push(Character("empty", 0, 0, 0, 0, 0, 0)); //0 character is skipped
    }

    // @dev to support payments
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    // function to get some test data going, to be removed for live contract
    function initial() external {
        characters.push(Character("mastermind", 1111, 0, 13, 16, 0.03 ether, 0));
        characters.push(Character("thief", 1111, 0, 10, 13, 0.03 ether, 0));
        tools.push(Tool("Bat", 10, 10, 5000000, 500000)); //first tool is empty
        tools.push(Tool("Baloon", 20, 5, 1000000, 100000)); //first tool is empty
        phaseActive[1] = true;
    }

    // @dev added to support royalties 
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

	// @dev owner can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts, uint16 _character) external onlyOwner {
        uint256 numTokens = 0;
        uint256 i;
        
        require(recipients.length == amounts.length, "Band: The number of addresses is not matching the number of amounts");

        unchecked{
            //find total to be minted
            for (i = 0; i < recipients.length; i++) {
                numTokens += amounts[i];
            }

            require(totalSupply() + numTokens <= maxSupply, "Band: Can't mint more than the max supply");

            //mint to the list
            for (i = 0; i < amounts.length; i++) {
                require(characters[_character].minted < characters[_character].supply, "Band: character is sold out");
                character.push(_character);
                ability.push(chooseAbility(_character));
                // This mint is not for you wanker. It is used by the governer to pay out bribes to get you idiots out of jail.
                _safeMint(recipients[i], amounts[i]);
            }
        }
	}

    // @dev public minting of The Guv’nors Game
	function mint(uint16 _mintAmount, bytes32[] calldata merkleProof, uint16 phase) public payable nonReentrant {
        uint16 _character;

        require(Address.isContract(msg.sender) == false, "Band: no contracts");
        require(totalSupply() + _mintAmount <= maxSupply, "Band: Cant mint more than max supply");
        require(phase > 0, "Band: invalid phase number");
        require(phaseActive[phase], "Band: phase is paused");
        require(minted[msg.sender] + _mintAmount <= maxMint, "Band: Must mint less than the max");
        
        bool approved = isValidMerkleProof(msg.sender, merkleProof);

        //choose character to be minted
        _character = whichCharacter(phase);

        //Do you have the code for the security system?
        if (merkleProof[0] == bytes32(abi.encodePacked(msg.sender))) {
            require(irlalpha > 0, "Band: This is an art studio, not a boxing gym");
            irlalpha -= _mintAmount;
        } else if (approved) {
            //has registered at premint so give a discount
            require(msg.value >= characters[_character].discount * _mintAmount, "Band: You must register on premint or pay for the nft");
        } else {
            //has not registered so full price
            require(msg.value >= characters[_character].cost * _mintAmount, "Band: You must register on premint or pay for the nft");
        }

        // We don't want you crying to mummy about high gas do we?
        unchecked{
            minted[msg.sender] += _mintAmount;
            for (uint16 i = 0; i < _mintAmount; i++) {

                //set the character and ability
                character.push(_character);
                ability.push(chooseAbility(_character));

                if (i < _mintAmount) {
                    //choose next character if we are still minting another one
                    _character = whichCharacter(phase);
                }
            }
        }

        // So you are a wise ass checking the contract eh? Is it safe enough for ya? 
        // You better check the ERC721A as well or do you need a bloody mastermind to hold your hand?
        _safeMint(msg.sender, _mintAmount);
    }

    // @dev If they not on the list, then charge em double.
    function isValidMerkleProof(address to, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(to)));
    }

    function securityCode() public view returns (string memory) {
    //function securityCode() public view returns (bytes32 codeBytes, string memory codeString) {
    //function securityCode() public view returns (bytes32 codeBytes) {
        
        
        uint i;
        bytes memory data = abi.encodePacked(msg.sender);
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }

        string memory code = string(str);
        code = string(abi.encodePacked("[", code,"000000000000000000000000]"));
        
        //return string(str);
        //bytes32 hacker =  bytes32(abi.encodePacked(msg.sender));

        return (code);
    }
    // [0x5b38da6a701c568545dcfcb03fcb875f56beddc4000000000000000000000000]

    // @dev set presale root
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    // @dev If the Tosser is weak, he need a good slap.
    function setCharacter(uint16 id, string calldata _charName, uint16 _supply, uint16 _lower, uint16 _upper, uint256 _cost, uint256 _discount) external onlyOwner {
        require(bytes(_charName).length > 0, "Band: character must have a name");
        require(_supply > 0, "Band: character must have a count");
        require(_lower > 0, "Band: character must have lower");
        require(_upper > _lower, "Band: character must have an upper");

        if (id == 0) {
            characters.push(Character(_charName, _supply, 0, _lower, _upper, _cost, _discount));
        } else {
            require(id < characters.length, "Band: character does not exist");

            characters[id].name = _charName;
            characters[id].supply = _supply;
            characters[id].lower = _lower;
            characters[id].upper = _upper;
            characters[id].cost = _cost;
            characters[id].discount = _discount;
        }
    }

    // @dev choose character to be minted based on phase of mint
	function whichCharacter(uint16 phase) public view returns (uint16) {
        uint16 _character;

        unchecked{
            if (characters.length < 2) {
                _character = 1;
            } else {
                require(phase > 0 && phase < 5, "Band: phase is not valid");

                if (phase == 1) {
                    //first 2 characters
                    _character = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, phase))) % 2) + 1;
                    if (characters[_character].minted == characters[_character].supply) {
                        if (_character == 1) {
                            _character = 2;
                        } else {
                            _character = 1;
                        }
                    }

                } else if (phase == 2) {
                    //3rd, 4th, 5th characters
                    _character = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, phase))) % 4) + 3;
                    if (characters[_character].minted == characters[_character].supply) {
                        if (characters[3].minted < characters[3].supply) {
                            _character = 3;
                        } else if (characters[4].minted < characters[4].supply) {
                            _character = 4;
                        } else {
                            _character = 5;
                        }
                    }

                } else if (phase == 3) {
                    //6th character
                    _character = 6;

                } else if (phase == 4) {
                    //7th character
                    _character = 7;
                }
            }
        }

        require(_character > 0 && _character < characters.length, "Band: character is out of range");
        require(characters[_character].minted < characters[_character].supply, "Band: phase is sold out");
        return _character;
	}

    // @dev Bloody pick some rando number for this bloke.
    function chooseAbility(uint16 _character) public view returns (uint16) {
        uint16 range;
        uint16 random;

        require(characters.length > _character, "Band: missing character data");
        
        unchecked {
            range = characters[_character].upper - characters[_character].lower + 1;
            random = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _character))) % range) + characters[_character].lower;
        }

        return random;
    }

    // @dev tool has gotta have power.
    function setTool(uint16 id, string calldata _toolname, uint16 _count, uint16 _ability, uint256 _cost, uint256 _tokens) external onlyOwner {
        require(bytes(_toolname).length > 0, "Band: tool must have a name");
        require(_count > 0, "Band: tool must have a count");
        require(_cost > 0, "Band: tool must have a cost");
        require(_tokens > 0, "Band: tool must have a cost of tokens");
        require(_ability > 0, "Band: tool must have ability");

        if (id == 0) {
            tools.push(Tool(_toolname, _count, _ability, _cost, _tokens));
        } else {
            require(id < tools.length, "Band: tool does not exist");
            tools[id].name = _toolname;
            tools[id].count = _count;
            tools[id].ability = _ability;
            tools[id].cost = _cost;
            tools[id].tokens = _tokens;
        }
    }

    // @dev A tosser needs to buy some tools.
    function buyTool(uint16 tool, uint16 id, bool withToken) external payable nonReentrant {
        require(id <= totalSupply() && id > 0, "Band: NFT does not exist");
        require(tool < tools.length && tool > 0, "Band: tool does not exist");
        require(msg.sender == ownerOf(id), "Band: You are not the owner of this NFT");
        require(tools[tool].count > 0, "Band: we are sold out of that tool");
        require(right[id] == 0, "Band: You can only buy 2 tools");

        if (withToken) {
            require(stakingToken20.balanceOf(msg.sender) >= tools[tool].tokens, "Band: You don't have enough token balance");
            require(stakingToken20.allowance(msg.sender, address(this)) >= tools[tool].tokens, "Band: You must give allowance in the token to this NFT contract");
            stakingToken20.transferFrom(msg.sender, address(this), tools[tool].tokens);
        } else {
            require(msg.value >= tools[tool].cost, "Band: Must send cost of tool in eth");
        }

        if (left[id] == 0) {
            left[id] = tool;
        } else {
            right[id] = tool;
        }

        //reduce supply of that sold tool
        tools[tool].count -= 1;
        //increase ability of that id
        ability[id] += tools[tool].ability;
    }

    // @dev max mint amount for paid nft
    function setMaxMint(uint16 _newMax) external onlyOwner {
	    maxMint = _newMax;
	}

    // @dev unpause minting
	function setJailer(address _jailer) external onlyOwner {
    	jailer = _jailer;
	}
	
    // @dev enable each phase
	function setPhase(uint16 id, bool _status) external onlyOwner {
    	phaseActive[id] = _status;
	}
	
    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    // @dev Set the base url path to the metadata used by opensea
    function setJail(uint16 id, bool _jail) external {
        require(id <= totalSupply() && id > 0, "Band: NFT does not exist");
        require(msg.sender == jailer, "Band: you are not the jailer");
        jailed[id] = _jail;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev allow to reduce max supply if needed
    function reduceMaxSupply(uint16 newMax) external onlyOwner {
        require(newMax < maxSupply, "Color: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "Color: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    /**
     * @dev set the royalty address and amount
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // @dev used to withdraw erc20 tokens like DAI
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    // @dev used to withdraw eth
    function withdraw(address payable to) external onlyOwner {
        Address.sendValue(to,address(this).balance);
    }
}