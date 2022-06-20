// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";

contract Flixu is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard, PaymentSplitter {

    string public constant name = "Flixu NFT";
    string private constant symbol = "FLX";
    string public baseURI = "https://ipfs.io/ipfs/QmVx8StF1DzRaepjjaGUXA79x4BEZU8BthLEwnXt4uWjyQ/";
    uint256 public ethPrice = 1087;
	bool public status = false;
	mapping(address => bool) public affiliateList;
	mapping(address => address) public referralList;
	mapping(address => address) public managerList;

    //each ID has this data
    struct Art {
        string artName;
        uint32 maxSupply;
        uint16 mintPrice;
        uint16 commission;
        uint16 referral;
        uint16 charge;
        address[] payees;
        uint16[] shares;
    }

    //array of data for each ID
    Art[] public arts;

    address[] private firstPayees = [msg.sender];
    uint16[] private firstShares = [100];

    constructor() ERC1155(baseURI) PaymentSplitter(firstPayees, firstShares) payable {
    }

    // @dev create a art that can be purchased
    function createArt(string memory _name, uint16 _cost, uint32 _count, uint16 _commission, uint16 _referral, uint16 _charge, address[] memory newPayees, uint16[] memory newShares) public onlyOwner {
        uint256 pendingTotal;

        require(_count > 0, "Flixu: art must have a count");
        require(_cost > 0, "Flixu: art must have a cost");
        require(newPayees.length > 0, "Flixu: art must have payees");
        require(newPayees.length == newShares.length, "Flixu: The number of shares is not matching the number of payees");
        require(_commission + _referral + _charge < 100, "Flixu: Commission is too high");

        for (uint16 j = 0; j < newPayees.length; j++) {
            require(Address.isContract(newPayees[j]) == false, "Flixu: no contracts");
            pendingTotal += newShares[j];
        }
        require(pendingTotal > 0, "Flixu: total shares must be greater than 0");

        arts.push(Art(_name, _count, _cost, _commission, _referral, _charge, newPayees, newShares));

        for (uint256 j = 0; j < newPayees.length; j++) {
            _addPayee(newPayees[j], 0); //make sure payee is in list, 0 shares as they don't get mint revenue
        }
    }

    //update existing art settings
    function setArt(uint256 id, string calldata _name, uint16 _cost, uint32 _count, uint16 _commission, uint16 _referral, uint16 _charge, address[] calldata newPayees, uint16[] calldata newShares) external onlyOwner {
        uint256 pendingTotal;

        require(_count >= totalSupply(id), "Flixu: New maximum can't be less than minted count");
        require(_cost > 0, "Flixu: art must have a cost");
        require(newPayees.length > 0, "Flixu: art must have payees");
        require(newPayees.length == newShares.length, "Flixu: The number of shares is not matching the number of payees");
        require(_commission + _referral + _charge < 100, "Flixu: Commission is too high");

        for (uint16 j = 0; j < newPayees.length; j++) {
            require(Address.isContract(newPayees[j]) == false, "Flixu: no contracts");
            pendingTotal += newShares[j];
        }
        require(pendingTotal > 0, "Flixu: total shares must be greater than 0");

        arts[id]=Art(_name, _count, _cost, _commission, _referral, _charge, newPayees, newShares);

        for (uint256 j = 0; j < newPayees.length; j++) {
            _addPayee(newPayees[j], 0); //make sure payee is in list, 0 shares as they don't get mint revenue
        }
    }

    // @dev shows the payees of a art
    function showArtPayees(uint16 id) public view returns (address[] memory) {
        return arts[id].payees;
    }

    // @dev shows the shares of each payee of a art
    function showArtShares(uint16 id) public view returns (uint16[] memory) {
        return arts[id].shares;
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

    //update uri
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

	// @dev admin can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts, uint256 id) external onlyOwner {
        uint256 numTokens;
        uint256 i;

        require(id <= arts.length, "Flixu: id not created yet");
        require(recipients.length > 0, "Flixu: missing recipients");
        require(recipients.length == amounts.length, 
            "Flixu: The number of addresses is not matching the number of amounts");

        //find total to be minted
        for (i = 0; i < recipients.length; i++) {
            numTokens += amounts[i];
            require(Address.isContract(recipients[i]) == false, "Flixu: no contracts");
        }

        require(totalSupply(id) + numTokens <= arts[id].maxSupply, "Flixu: Can't mint more than the max supply");

        //mint to the list
        for (i = 0; i < recipients.length; i++) {
            _mint(recipients[i], id, amounts[i], "");
        }
	}

    // @dev public minting
    function mint(uint256 _mintAmount, uint256 id, address affiliate) external payable nonReentrant {
        uint256 supply = totalSupply(id);
        uint256 totalArtShares;
        uint16 j;

        require(Address.isContract(affiliate) == false, "Flixu: no contracts");
        require(status, "Flixu: Minting not started yet");
        require(_mintAmount > 0, "Flixu: Cant mint 0");
        require(id <= arts.length, "Flixu: ID not created yet");
        require(supply + _mintAmount <= arts[id].maxSupply, "Flixu: Cant mint more than max supply");

        require(msg.value >= cost(id) * _mintAmount, "Flixu: Must send eth of cost per nft");
        require(Address.isContract(msg.sender) == false, "Flixu: no contracts");

        _mint(msg.sender, id, _mintAmount, "");

        //find total shares to be paid for the art sale
        for (j = 0; j < arts[id].payees.length; j++) {
            totalArtShares += arts[id].shares[j];
        }

        //if address is owner then no payout
        if (affiliate != address(0) && affiliate != owner() && arts[id].commission > 0 && msg.value > 0) {
            //if only recorded affiliates can receive payout
            if (affiliateList[affiliate]) {
                artShares[affiliate] += msg.value * arts[id].commission / 100;
                artBalance += msg.value * arts[id].commission / 100;

                if (referralList[affiliate] == address(0) || referralList[affiliate] == owner()) {
                    //pay the affiliate a commission
                    totalArtShares = totalArtShares * 100 / (100 - arts[id].commission);
                } else {

                    artShares[referralList[affiliate]] += msg.value * arts[id].referral / 100;
                    artBalance += msg.value * arts[id].referral / 100;
                    if (managerList[referralList[affiliate]] == address(0) || managerList[referralList[affiliate]] == owner()) {
                        //pay the referrer of the affiliate the commission
                        totalArtShares = totalArtShares * 100 / (100 - arts[id].commission - arts[id].referral);

                    } else {
                        //pay the referrer and the manger of the affiliate the commission
                        artShares[managerList[referralList[affiliate]]] += msg.value * arts[id].charge / 100;
                        artBalance += msg.value * arts[id].charge / 100;
                        totalArtShares = totalArtShares * 100 / (100 - arts[id].commission - arts[id].referral - arts[id].charge);
                    }
                }
            }
        }

        //record payment split for payees of art
        if (totalArtShares > 0 && msg.value > 0) {
            for (j = 0; j < arts[id].payees.length; j++) {
                artShares[arts[id].payees[j]] += msg.value * arts[id].shares[j] / totalArtShares;
                artBalance += msg.value * arts[id].shares[j] / totalArtShares;
            }
        }
    }

    // @dev record affiliate address
	function allowAffiliate(address newAffiliate, bool allow, address referral) external onlyOwner {
        affiliateList[newAffiliate] = allow;
        referralList[newAffiliate] = referral;
        _addPayee(newAffiliate, 0);
        _addPayee(referral, 0);
	}

    //set the manager of the referrer
    function setManager(address _referral, address _manager) external onlyOwner {
        managerList[_referral] = _manager;
        _addPayee(_manager, 0);
    }

   // @dev unpause main minting stage
	function setStatus(bool _status) external onlyOwner {
    	status = _status;
	}
	
    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    // @dev Set the price of ethereum
    function setEth(uint256 price) external onlyOwner {
        require(price > 0, "Flixu: price is invalid");
        ethPrice = price;
    }

    //show the cost of the nft for that id
    function cost(uint256 id) public view returns (uint256) {
        return uint256(arts[id].mintPrice) * 1e18 / ethPrice;
    }

    //show how many id are created
    function maxID() public view returns (uint256) {
        return arts.length;
    }

    // @dev release payments for minting and art purchases to one payee
    function release(address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Flixu: no contracts");
        _release(account);
    }
    
    // @dev release ERC20 tokens due to a payee
    function releaseToken(IERC20 token, address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Flixu: no contracts");
        _releaseToken(token, account);
    }
    
    // @dev anyone can run withdraw which will send all payments for minting and art purchases
    function withdraw() external nonReentrant {
        _withdraw();
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI,Strings.toString(_tokenId),".json"));
    }
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override (ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}