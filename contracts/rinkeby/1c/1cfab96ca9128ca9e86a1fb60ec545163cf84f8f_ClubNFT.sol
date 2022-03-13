// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

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

    // each pill looks like
    struct Pill {
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
    uint16[][] private myPills; // store pills in each nft
    uint8 public maxPills = 9; //max pills per nft
    uint8 public maxMint = 5; //per transaction
	bool public status = false;
	bool public presale = false;
    bool public freeze = false;
	mapping(address => uint8) public presaleList;
    Pill[] public pills; // store a list of pills

    //starting payee is deployer
    address[] private firstPayees = [msg.sender];
    uint16[] private firstShares = [100];

    constructor() ERC721A("Digital Drug Club", "DDCX") PaymentSplitter(firstPayees, firstShares) payable {
        pills.push(Pill("empty", 1, 1, firstPayees, firstShares)); //first pill is empty
        myPills.push([0]); //skip first as ID starts at 1
    }

	// @dev admin can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint16[] calldata amounts) external onlyOwner {
        uint16 numTokens;
        uint16 i;
        uint256 j;
        uint256 supply;

        require(recipients.length == amounts.length, 
            "Club: The number of addresses is not matching the number of amounts");

        //find total to be minted
        for (i = 0; i < recipients.length; i++) {
            require(Address.isContract(recipients[i]) == false, "Club: no contracts");
            numTokens += amounts[i];
        }

        require(numTokens < 200, "Club: Minting more than 200 may get stuck");
        require(totalSupply() + numTokens <= maxSupply, "Club: Can't mint more than the max supply");

        //mint to the list
        for (i = 0; i < amounts.length; i++) {
            _safeMint(recipients[i], amounts[i]);

            //record empty pill
            supply = totalSupply();
            for (j = 0; j < amounts[i]; j++) {
                myPills.push([0]);
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

        //record empty pill
        for (uint256 j = 0; j < _mintAmount; j++) {
            myPills.push([0]);
        }
	}

    // @dev create a pill that can be purchased
    function createPill(string calldata _name, uint64 _cost, uint16 _count, address[] calldata newPayees, uint16[] calldata newShares) external onlyOwner {
        require(bytes(_name).length > 0, "Club: pill must have a name");
        require(_count > 0, "Club: pill must have a count");
        require(_cost > 0, "Club: pill must have a count");
        require(newPayees.length > 0, "Club: pill must have payees");
        require(newPayees.length == newShares.length, 
            "Club: The number of shares is not matching the number of payees");

        for (uint16 j = 0; j < newPayees.length; j++) {
            require(address(newPayees[j]) != address(0), "Club: payee must not be 0");
            require(Address.isContract(newPayees[j]) == false, "Club: no contracts");
        }

        pills.push(Pill(_name, _count, _cost, newPayees, newShares));

        for (uint256 j = 0; j < newPayees.length; j++) {
            addPayee(newPayees[j], 0); //make sure payee is in list, 0 shares as they don't get mint revenue
        }
    }

    // @dev set max number of pills per nft
	function setMaxPills(uint8 _newMax) external onlyOwner {
    	maxPills = _newMax;
	}

    // @dev change the name of a pill
    function setPillName(string calldata newName, uint16 id) external onlyOwner {
        require(bytes(newName).length > 0, "Club: pill must have a name");
        pills[id].name = newName;
    }

    // @dev change the cost of a pill
    function setPillCost(uint64 newCost, uint16 id) external onlyOwner {
        pills[id].cost = newCost;
    }

    // @dev change the count available of a pill
    function setPillCount(uint16 newCount, uint16 id) external onlyOwner {
        pills[id].count = newCount;
    }

    // @dev shows the payees of a pill
    function showPillPayees(uint16 id) public view returns (address[] memory) {
        return pills[id].payees;
    }

    // @dev shows the shares of each payee of a pill
    function showPillShares(uint16 id) public view returns (uint16[] memory) {
        return pills[id].shares;
    }

    // @dev replace the payees of a pill
    function setPillPayee(uint16 id, address[] calldata newPayees, uint16[] calldata newShares) external onlyOwner {
        uint16 j;

        require(newPayees.length > 0, "Club: pill must have payees");
        require(newPayees.length == newShares.length, 
            "Club: The number of shares is not matching the number of payees");

        for (j = 0; j < newPayees.length; j++) {
            require(address(newPayees[j]) != address(0), "Club: payee must not be 0");
            require(Address.isContract(newPayees[j]) == false, "Club: no contracts");
        }

        //send existing payments first so that next payment is correct
        for (j = 0; j < pills[id].payees.length; j++) {
            if (pillShares[pills[id].payees[j]] > 0) {
                _release(payable(pills[id].payees[j]));
            }
        }

        //remove previous pill payees
        for (j = 0; j < pills[id].payees.length; j++) {
            pills[id].payees.pop();
            pills[id].shares.pop();
        }

        //add new pill payees
        for (j = 0; j < newPayees.length; j++) {
            pills[id].payees.push(newPayees[j]);
            pills[id].shares.push(newShares[j]);
            addPayee(newPayees[j], 0); //make sure payee is in list, 0 shares as they don't get mint revenue
        }
    }

    // @dev an owner of a NFT can buy a pill to add to their set
    function buyPill(uint16 pill, uint16 id) external payable nonReentrant {
        uint256 j;
        uint256 totalPillShares;

        require(Address.isContract(msg.sender) == false, "Club: no contracts");
        require(id <= totalSupply() && id > 0, "Club: NFT does not exist"); // 0 pill is default value not to be used
        require(pill > 0, "Club: must choose a pill"); // 0 pill is default value not to be used
        require(pill < pills.length, "Club: pill does not exist");
        require(totalSupply() >= id, "Club: nft does not exist");
        require(msg.sender == ownerOf(id) || msg.sender == owner(), "Club: You are not the owner of this NFT");
        require(pills[pill].count > 0, "Club: we are sold out of that pill");
        //require(msg.value >= pills[pill].cost || msg.sender == owner(), "Club: Must send cost of pill in eth");
        require(msg.value >= pills[pill].cost, "Club: Must send cost of pill in eth");
        require(myPills[id].length < maxPills, "Club: your pills are full");

        if (myPills[id][0] == 0) {
            //set the first pill
            myPills[id][0] = pill;
        } else {
            //record the next pill
            myPills[id].push(pill);
        }

        //reduce supply of that sold pill
        pills[pill].count--;

        //find total shares to be paid for the pill sale
        for (j = 0; j < pills[pill].payees.length; j++) {
            totalPillShares = totalPillShares + pills[pill].shares[j];
        }

        //record payment split for payees of pill
        for (j = 0; j < pills[pill].payees.length; j++) {
            pillShares[pills[pill].payees[j]] = pillShares[pills[pill].payees[j]] + (msg.value * pills[pill].shares[j] / totalPillShares);
        }

        pillBalance = pillBalance + msg.value;
    }

    // @dev show the set of pill numbers purchased
    function showPillSet(uint16 id) public view returns (uint16[] memory) {
        require(id <= totalSupply(), "Club: NFT does not exist");
        return myPills[id];
    }

    // @dev show the names of pills purchased
    function showPillNames(uint16 id) public view returns (string[9] memory) {
        uint16 pillNumber;
        uint16[] memory pillSet;
        string memory pillName;
        string[9] memory pillNames;

        require(id <= totalSupply(), "Club: NFT does not exist");

        pillSet = myPills[id]; //pills set owned by 1 NFT
        for(uint16 i = 0; i < pillSet.length; i++) {
            pillNumber = pillSet[i]; //pill number of each pill owned by 1 NFT
            pillName = pills[pillNumber].name; //name of pill
            pillNames[i] = pillName; //name of each pill owned
        }

        return pillNames;
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
    function addPayee(address account, uint16 shares_) public onlyOwner {
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

    // @dev freeze the URI after all pills are purchased
    function freezeURI() external onlyOwner {
        freeze = true;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev release payments for minting and pill purchases to one payee
    function release(address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Club: no contracts");
        _release(account);
    }

    // @dev release ERC20 tokens due to a payee
    function releaseToken(IERC20 token, address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Club: no contracts");
        _releaseToken(token, account);
    }

    // @dev anyone can run withdraw which will send all payments for minting and pill purchases
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