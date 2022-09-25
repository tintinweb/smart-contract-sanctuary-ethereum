// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// This is an NFT for Fullmoon NFT https://
//

import "./ERC721A.sol";
import "./IERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./PaymentSplitter.sol";

contract Fullmoon is
    ERC721A,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable,
    ERC2981
{

    bool public moonbirdOpen = false;
    bool public publicOpen = false;
    bool public upgradesOpen = false;
    bool public freezeURI = false;
    bool[10000] public claimed;
    bool[10000][10] public chosenUpgrade;
    string private constant _name = "Fullmoon Birds";
    string private constant _symbol = "FULL";
    string public baseURI = "https://ipfs.io/ipfs/QmPnbNRjn4bSL7rsuiX8hAvkwd8CKjB7jZYzcvRXNuDTWk/";
    uint16 public maxSupply = 10000;
    uint16 public maxMint = 3;
    uint16[20][5] public traitRarity;
    uint16[10000][6] public moonbirdID;
    uint256 public cost = 0.03 ether;
	mapping(address => uint16) public minted;
    IERC721A public Moonbirds = IERC721A(0x3332dBA7f4a023Ece32Fc83a172CFe775384141f);
    address public admin = msg.sender;

    struct Upgrade {
        bool anyone;
        string name;
        uint16 supply;
        uint256 cost;
    }
    Upgrade[] public upgrades;

    address[] private firstPayees = [0x67935A1b7E18D16d55f9Cc3638Cc612aBf3ff800, 0x9FcFD77494a0696618Fab4568ff11aCB0F0e5d9C, 0x1380c8aa439AAFf8CEf5186350ce6b08a6062E90, 0xa4D89eb5388613A9BF7ED0eaFf5fD2c05a4B34e3];
    uint256[] private firstShares = [500, 166, 166, 167];

    constructor() ERC721A(_name, _symbol) PaymentSplitter(firstPayees, firstShares) payable {
        _setDefaultRoyalty(address(this), 500);
        upgrades.push(Upgrade(false,"Locked", 10000, 0.03 ether));
    }

    // setup traits for testing
    function test() external onlyAdmin {
        uint16 i;
        uint16 j;
        for (j = 0; j < 5; j += 1) {
            for (i = 0; i < 20; i += 1) {
                traitRarity[j][i] = 10;
            }
        }
        moonbirdOpen = true;
        publicOpen = true;
        cost = 1000000000000;
        upgradesOpen = true;
        upgrades.push(Upgrade(false, "Cage", 1000, 1000000000000));
        upgrades.push(Upgrade(true, "UFO", 1000, 1000000000000));
    }

    // @dev public minting
	function mint(uint16 mintAmount, bool custom, uint16 claimId, uint16[5] memory requestTrait) external payable nonReentrant {
        uint16 found;
        uint16 start;
        uint16 i;
        uint16 j;
        uint16 k;

        require(Address.isContract(msg.sender) == false, "Fullmoon: no contracts");
        require(totalSupply() + mintAmount <= maxSupply, "Fullmoon: Can't mint more than max supply");

        unchecked {
            if (msg.sender == owner() || msg.sender == admin) {
                mintAmount = 1;
                custom = true;
                require(claimed[claimId] == false, "Fullmoon: already minted that one");

            } else if (custom && moonbirdOpen) {
                mintAmount = 1;
                require(Moonbirds.ownerOf(claimId) == msg.sender, "Fullmoon: not owner of that Moonbird");
                require(claimed[claimId] == false, "Fullmoon: already minted that one");
                require(msg.value >= cost, "Fullmoon: you must pay for the nft");

            } else if (publicOpen) {
                require(mintAmount + minted[msg.sender] <= maxMint, "Fullmoon: Must mint less than this quantity");
                require(msg.value >= cost * mintAmount, "Fullmoon: You must pay for the nft");

            } else {
                require(false, "Fullmoon: minting is not open yet");
            }

            if (custom) {
                //ID starts at 0
                moonbirdID[0][totalSupply()] = claimId;
                claimed[claimId] = true;
                for (i = 0; i < 5; i += 1) {
                    require(traitRarity[i][requestTrait[i]] > 0, "Fullmoon: that trait is no longer availble");
                    moonbirdID[i + 1][totalSupply()] = requestTrait[i];
                    traitRarity[i][requestTrait[i]] -= 1;
                }
            } else {
                for (j = 0; j < mintAmount; j += 1) {
 
                    //choose a random id to start finding an unclaimed Moonbird
                    start = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, mintAmount * (j + 1)))) % 99);
                    if (start > 98 || start == 0) {
                        start = 50;
                    }

                    found = 0;
                    for (i = start; i < 100; i += 1) {
                        if (claimed[i] == false) {
                            found = 1;
                            break;
                        }
                    }
                    if (found == 0) {
                        for (i = start; i > 0; i -= 1) {
                            if (claimed[i] == false) {
                                found = 1;
                                break;
                            }
                        }
                    }

                    require(found == 1, "Fullmoon: can't find available moonbird");
                    claimed[i] = true;
                    moonbirdID[0][totalSupply() + j] = i;

                    //choose random variations of each trait for each NFT to be minted
                    // loop for each trait
                    for (k = 0; k < 5; k += 1) {
                        //choose random starting number to start search for available variation
                        start = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, (j + 1) * (k + 1)))) % 19);
                        if (start > 18 || start == 0) {
                            start = 10;
                        }
                        //l = start;
                        found = 0;
                        for (i = start; i < 19; i += 1) {
                            if (traitRarity[k][i] > 0) {
                                found = 1;
                                break;
                            }
                        }
                        if (found == 0) {
                            for (i = start; i > 0; i -= 1) {
                                if (traitRarity[k][i] > 0) {
                                    found = 1;
                                    break;
                                }
                            }
                        }
                        require(found == 1, "Fullmoon: trait cannot be chosen");
                        moonbirdID[k + 1][totalSupply() + j] = i;
                        traitRarity[k][i] -= 1;
                    }
                }
            }
        }

        minted[msg.sender] += mintAmount;
        _safeMint(msg.sender, mintAmount);
	}

    // set the quantity available for each variation of one trait
    function setTrait(uint16 traitNum, uint16[20] memory rarity) external onlyAdmin {
        for (uint16 i = 0; i < 20; i += 1) {
            traitRarity[traitNum][i] = rarity[i];
        }
    }

    // show for an nft which Moonbird ID and traits are used
    function traitValues(uint16 id) public view returns (uint16[6] memory traits) {
        for (uint16 k = 0; k < 6; k += 1) {
            traits[k] = moonbirdID[k][id];
        }
        return traits;
    }

    // allow upgrades to be changed or created
    function setUpgrade(bool add, uint16 upgradeId, bool newAnyone, string memory newName, uint16 newSupply, uint256 newCost) external onlyAdmin {
        if (add) {
            require(upgrades.length < 11, "Fullmoon: only 10 upgrades are supported");
            upgrades.push(Upgrade(newAnyone, newName, newSupply, newCost));
        } else {
            require(upgradeId < upgrades.length, "Fullmoon: id does not exist");
            upgrades[upgradeId].anyone = newAnyone;
            upgrades[upgradeId].name = newName;
            upgrades[upgradeId].supply = newSupply;
            upgrades[upgradeId].cost = newCost;
        }
    }

    // upgrades can be purchased
    function buyUpgrade(uint16 upgradeId, uint16 tokenId, bool enable) external payable nonReentrant {
        require(upgradeId < upgrades.length, "Fullmoon: id does not exist");
        require(upgradesOpen || upgradeId == 0 || msg.sender == owner(), "Fullmoon: upgrades are not enabled yet");
        require(tokenId < totalSupply(), "Fullmoon: token does not exist");
        require(chosenUpgrade[upgradeId][tokenId] != enable, "Fullmoon: already purchased");

        if (msg.sender != owner() && msg.sender != admin &&
                (upgradeId == 0 || upgrades[upgradeId].anyone == false || chosenUpgrade[0][tokenId])) {
            //   locking option    upgrade is only availble to owner      token has been locked
            require(ownerOf(tokenId) == msg.sender, "Fullmoon: this can only be purchased by the owner");
        }

        if (msg.sender != owner() && msg.sender != admin) {
            require(upgrades[upgradeId].supply > 0,"Fullmoon: upgrade is sold out");
            require(msg.value >= upgrades[upgradeId].cost, "Fullmoon: this upgrade is not free");
        }

        upgrades[upgradeId].supply -= 1;
        chosenUpgrade[upgradeId][tokenId] = enable;
    }

    // @dev max mint amount for paid nft
    function setMaxMint(uint16 _newMax) external onlyAdmin {
	    maxMint = _newMax;
	}

    // @dev set cost of minting
	function setCost(uint256 _newCost) external onlyAdmin {
    	cost = _newCost;
	}
			
    // @dev allow anyone to mint
	function setPublicOpen(bool _status) external onlyAdmin {
    	publicOpen = _status;
	}

    // @dev allow Moonbird owners to mint
	function setMoonbirdOpen(bool _status) external onlyAdmin {
    	moonbirdOpen = _status;
	}

    // @dev allow Moonbird owners to mint
	function setUpgradesOpen(bool _status) external onlyAdmin {
    	upgradesOpen = _status;
	}

    // set the second owner
    function setAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyAdmin {
        require(freezeURI == false, "Fullmoon: uri is frozen");
        baseURI = _baseTokenURI;
    }

    // @dev freeze the URI
    function setFreezeURI() external onlyAdmin {
        freezeURI = true;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //reduce max supply if needed
    function reduceMaxSupply(uint16 newMax) external onlyAdmin {
        require(newMax < maxSupply, "Fullmoon: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "Fullmoon: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner() || msg.sender == admin, "Fullmoon: only for owner");
        _;
    }

    //to support royalties
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //set royalties
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyAdmin {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}