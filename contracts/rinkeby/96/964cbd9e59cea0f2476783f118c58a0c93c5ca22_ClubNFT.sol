// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

// This is an NFT for Band of Crazy https://bandofcrazy.com/
// Smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski
// Thanks to chiru-labs for their gas friendly ERC721A implementation.

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract ClubNFT is
    ERC721A,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable
{
    using Strings for uint256;
    using SafeMath for uint256;

    // each toy looks like
    struct Toy {
        string name;
        uint16 count;
        uint64 cost;
        address[] payees;
        uint16[] shares;
    }

    string public baseURI = "https://ipfs.io/ipfs/QmRxg7EhFZVyZPiWsR9wYFcKH1k81dsGedp3Eip5PcPAGF/";
    uint256 public mintPrice = 0.01 ether;
    uint16 public maxSupply = 7777;
    uint16 public presaleCount;
    uint16[][] private myToys; // store toys in each nft
    uint8 public maxToys = 9; //max toys per nft
    uint8 public maxMint = 5; //per transaction
	bool public status = false;
	bool public presale = false;
    bool public freeze = false;
	mapping(address => uint8) public presaleList;
    Toy[] public toys; // store a list of toys

    //starting payee is deployer
    address[] private firstPayees = [msg.sender];
    uint16[] private firstShares = [100];

    constructor() ERC721A("Band Of Crazy Party Pack", "BOCPP") PaymentSplitter(firstPayees, firstShares) payable {
        toys.push(Toy("empty", 1, 1, firstPayees, firstShares)); //first toy is empty
        myToys.push([0]); //skip first as ID starts at 1
    }

	// @dev admin can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint16[] calldata amounts) external onlyOwner {
        uint16 numTokens;
        uint16 i;
        uint256 j;

        require(recipients.length == amounts.length, "Club: The number of addresses is not matching the number of amounts");

        //find total to be minted
        for (i = 0; i < recipients.length; i++) {
            require(Address.isContract(recipients[i]) == false, "Club: no contracts");
            numTokens += amounts[i];
        }

        require(totalSupply() + numTokens <= maxSupply, "Club: Can't mint more than the max supply");

        //mint to the list
        for (i = 0; i < amounts.length; i++) {
            _safeMint(recipients[i], amounts[i]);

            //record empty toy
            for (j = 0; j < amounts[i]; j++) {
                myToys.push([0]);
            }
        }
	}

    // @dev public minting
	function mint(uint8 _mintAmount) external payable nonReentrant {
        uint256 supply = totalSupply();

        require(Address.isContract(msg.sender) == false, "Club: no contracts");
        require(status || presale, "Club: Minting not started yet");
        require(_mintAmount > 0, "Club: Cant mint 0");
        require(_mintAmount <= maxMint, "Club: Must mint less than the max");
        require(supply + _mintAmount <= maxSupply, "Club: Cant mint more than max supply");
        require(msg.value >= mintPrice * _mintAmount, "Club: Must send eth of cost per nft");

        if (presale && !status) {
            uint8 reserve = presaleList[msg.sender];
            require(reserve > 0, "Club: None left for you");
            require(_mintAmount <= reserve, "Club: Cant mint more than your allocation");
            presaleList[msg.sender] = reserve - _mintAmount;
        }
 
        _safeMint(msg.sender, _mintAmount);

        //record empty toy
        for (uint256 j = 0; j < _mintAmount; j++) {
            myToys.push([0]);
        }
	}

    // @dev create a toy that can be purchased
    function createToy(string calldata _name, uint64 _cost, uint16 _count, address[] calldata newPayees, uint16[] calldata newShares) external onlyOwner {
        uint256 pendingTotal;

        require(bytes(_name).length > 0, "Club: toy must have a name");
        require(_count > 0, "Club: toy must have a count");
        require(_cost > 0, "Club: toy must have a cost");
        require(newPayees.length > 0, "Club: toy must have payees");
        require(newPayees.length == newShares.length, "Club: The number of shares is not matching the number of payees");

        for (uint16 j = 0; j < newPayees.length; j++) {
            require(address(newPayees[j]) != address(0), "Club: payee must not be 0");
            require(Address.isContract(newPayees[j]) == false, "Club: no contracts");
            pendingTotal += newShares[j];
        }
        require(pendingTotal > 0, "Club: total shares must be greater than 0");

        toys.push(Toy(_name, _count, _cost, newPayees, newShares));

        for (uint256 j = 0; j < newPayees.length; j++) {
            _addPayee(newPayees[j], 0); //make sure payee is in list, 0 shares as they don't get mint revenue
        }
    }

    // @dev set max number of toys per nft
	function setMaxToys(uint8 _newMax) external onlyOwner {
    	maxToys = _newMax;
	}

    // @dev change the name of a toy
    function setToyName(string calldata newName, uint16 id) external onlyOwner {
        require(bytes(newName).length > 0, "Club: toy must have a name");
        toys[id].name = newName;
    }

    // @dev change the cost of a toy
    function setToyCost(uint64 newCost, uint16 id) external onlyOwner {
        toys[id].cost = newCost;
    }

    // @dev change the count available of a toy
    function setToyCount(uint16 newCount, uint16 id) external onlyOwner {
        toys[id].count = newCount;
    }

    // @dev shows the payees of a toy
    function showToyPayees(uint16 id) public view returns (address[] memory) {
        return toys[id].payees;
    }

    // @dev shows the shares of each payee of a toy
    function showToyShares(uint16 id) public view returns (uint16[] memory) {
        return toys[id].shares;
    }

    // @dev replace the payees of a toy
    function setToyPayee(uint16 id, address[] calldata newPayees, uint16[] calldata newShares) external onlyOwner {
        uint16 j;
        uint256 pendingTotal;

        require(newPayees.length > 0, "Club: toy must have payees");
        require(newPayees.length == newShares.length, "Club: The number of shares is not matching the number of payees");

        for (j = 0; j < newPayees.length; j++) {
            require(address(newPayees[j]) != address(0), "Club: payee must not be 0");
            require(Address.isContract(newPayees[j]) == false, "Club: no contracts");
            pendingTotal += newShares[j];
        }
        require(pendingTotal > 0, "Club: total shares must be greater than 0");

        //send existing payments first so that next payment is correct
        for (j = 0; j < toys[id].payees.length; j++) {
            if (toyShares[toys[id].payees[j]] > 0) {
                _release(payable(toys[id].payees[j]));
            }
        }

        //remove previous toy payees
        for (j = 0; j < toys[id].payees.length; j++) {
            toys[id].payees.pop();
            toys[id].shares.pop();
        }

        //add new toy payees
        for (j = 0; j < newPayees.length; j++) {
            toys[id].payees.push(newPayees[j]);
            toys[id].shares.push(newShares[j]);
            _addPayee(newPayees[j], 0); //make sure payee is in list, 0 shares as they don't get mint revenue
        }
    }

    // @dev an owner of a NFT can buy a toy to add to their set
    function buyToy(uint16 toy, uint16 id) external payable nonReentrant {
        uint256 j;
        uint256 totalToyShares;

        require(Address.isContract(msg.sender) == false, "Club: no contracts");
        require(id <= totalSupply() && id > 0, "Club: NFT does not exist");
        require(toy < toys.length && toy > 0, "Club: toy does not exist"); // 0 toy is default value not to be used
        require(id <= totalSupply(), "Club: nft does not exist");
        require(msg.sender == ownerOf(id), "Club: You are not the owner of this NFT");
        require(toys[toy].count > 0, "Club: we are sold out of that toy");
        require(myToys[id].length < maxToys, "Club: your toys are full");
        require(msg.value >= toys[toy].cost, "Club: Must send cost of toy in eth");

        if (myToys[id][0] == 0) {
            //set the first toy
            myToys[id][0] = toy;
        } else {
            //record the next toy
            myToys[id].push(toy);
        }

        //reduce supply of that sold toy
        toys[toy].count--;

        //find total shares to be paid for the toy sale
        for (j = 0; j < toys[toy].payees.length; j++) {
            totalToyShares = totalToyShares + toys[toy].shares[j];
        }

        //record payment split for payees of toy
        for (j = 0; j < toys[toy].payees.length; j++) {
            if (totalToyShares == 0) {
                toyShares[toys[toy].payees[j]] = 0;
            } else {
                toyShares[toys[toy].payees[j]] = toyShares[toys[toy].payees[j]] + (msg.value * toys[toy].shares[j] / totalToyShares);
            }
        }

        toyBalance = toyBalance + msg.value;
    }

    // @dev show the set of toy numbers purchased
    function showToySet(uint16 id) public view returns (uint16[] memory) {
        require(id <= totalSupply(), "Club: NFT does not exist");
        return myToys[id];
    }

    // @dev show the names of toys purchased
    function showToyNames(uint16 id) public view returns (string[9] memory) {
        uint16 toyNumber;
        uint16[] memory toySet;
        string memory toyName;
        string[9] memory toyNames;

        require(id <= totalSupply(), "Club: NFT does not exist");

        toySet = myToys[id]; //toys set owned by 1 NFT
        for(uint16 i = 0; i < toySet.length; i++) {
            toyNumber = toySet[i]; //toy number of each toy owned by 1 NFT
            toyName = toys[toyNumber].name; //name of toy
            toyNames[i] = toyName; //name of each toy owned
        }

        return toyNames;
    }

	// @dev record addresses of presale list
	function presaleSet(address[] calldata _addresses, uint8[] calldata _amounts) external onlyOwner {
        uint8 previous;

        require(_addresses.length == _amounts.length,
            "Club: The number of addresses is not matching the number of amounts");

        for(uint16 i; i < _addresses.length; i++) {
            require(Address.isContract(_addresses[i]) == false, "Club: no contracts");

            previous = presaleList[_addresses[i]];
            presaleList[_addresses[i]] = _amounts[i];
            presaleCount = presaleCount + _amounts[i] - previous;
        }
	}

    // @dev Add payee for payment splitter
    function addPayee(address account, uint16 shares_) external onlyOwner {
        _addPayee(account, shares_);
    }

    // @dev Set the number of shares for payment splitter
    function setShares(address account, uint16 shares_) external onlyOwner {
        _setShares(account, shares_);
    }

    // @dev add tokens that are used by payment splitter
    function addToken(address account) external onlyOwner {
        _addToken(account);
    }

    // @dev set cost of minting
	function setMintPrice(uint256 _newmintPrice) external onlyOwner {
    	mintPrice = _newmintPrice;
	}
		
    // @dev max mint amount per transaction
    function setMaxMint(uint8 _newMaxMintAmount) external onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

    // @dev unpause main minting stage
	function setSaleStatus(bool _status) external onlyOwner {
    	status = _status;
	}
	
    // @dev unpause presale minting stage
	function setPresaleStatus(bool _presale) external onlyOwner {
    	presale = _presale;
	}

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        require(freeze == false, "CryptoMofayas: uri is frozen");
        baseURI = _baseTokenURI;
    }

    // @dev freeze the URI after all toys are purchased
    function freezeURI() external onlyOwner {
        freeze = true;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev release payments for minting and toy purchases to one payee
    function release(address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Club: no contracts");
        _release(account);
    }

    // @dev release ERC20 tokens due to a payee
    function releaseToken(IERC20 token, address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Club: no contracts");
        _releaseToken(token, account);
    }

    // @dev anyone can run withdraw which will send all payments for minting and toy purchases
    function withdraw() external nonReentrant {
        _withdraw();
    }

    // @dev used to reduce the max supply instead of a burn
    function reduceMaxSupply(uint16 newMax) external onlyOwner {
        require(newMax < maxSupply, "Club: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "Club: New maximum can't be less than minted count");
        maxSupply = newMax;
    }
}