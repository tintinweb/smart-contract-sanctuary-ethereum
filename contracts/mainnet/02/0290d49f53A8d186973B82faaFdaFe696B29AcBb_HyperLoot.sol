// SPDX-License-Identifier: MIT

//MWN0o:;;;;;;;;:;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cd00d:;;;;;;;;;,,lxkkkkxo:',;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:lkKKOO0dc;;;;;;;:cxKWMMM
//XOdc,.....''''''''....'',,,,''.............................................................',:c;'...........;x0KKOxc............................................................';cc;;:;'........';okKWM
//l;'......,okOOOkdc'...'lxkOkd:..............................................................................;xKKkdl,................................................................................,cx0
//,.........cOKKOxl'.....;dOOxl'..............................................................................;xXKxol,.................''''''......................'....................................,;
//,.........:kK0xo:......:xOxo:':lodddo:'......,looolc,,cooooooooolc,..'coooooooooooooo:'.;oddddddddddddoc,...;xK0xoc,............',codxkkkkxxdl:'..........',clddxxxddoc;'....'lddddddddddddddddol;....,'
//,.........;xK0xo:......cO0xo;.'lxO0Okl'.....'l0KOxo:.,kXKOkxkkkkOOko,,dKX0Okdddddddxxl,'cOX0kkkkkkkOOO00x:..;xK0dlc,..........,lx000OkkxxxkkO0Oxl,......,lk000OOkkkOO00Oxl;..;kOxxdxkO000kxdddodo:'..','
//,.........;xK0xdl;,,,,:dKKxo;...,lddxdl,...;d00xl;'..'xXOdc'.'';lxkx:'l00xl;'.......,,'.;x0xl,'''',:cokkxc'.;d0Odl:,........'ckKKOxoc;,,,,;:ldxkkdc'..,lOK0kxlc:;;;:cldxkkxc',c;...';lddolc,....,,'..','
//,'.......';d00kkkkkkkO0KKOdl;.....;lodxdc;lk0ko:'....'dKkd:..'':dOxo;'cO0x:'............,x0xc'...',:ok0xl;..;d0Odl:,.......'cOX0xo:'........':dkkxd:',dKKOdl;'........;oxkkdc'.......cdddo:'.........','
//,'.''''''';d00kdddxxxxxxxoll;..'...':ldkOO0Odc,...''.'o0OkxxxkO00ko:,.:kOxl;'''',:c,....,dOkxdxxkkkOOOxo:'..;dOOoc:'''''''.,xX0xo:'..''''''...cO0kdl,c0KOdc,...'''''...;x0kxl;..'''.'lkxdl;'.'''..'''','
//,'',,,,,,,;dOkolc:;,,,:loolc;'',,,'..,ldkkxo:''',,,,''oOOxddddddoc;,''cxOkddoooddxd;',,',dOkxxkxddollc:,'.',;oOkol:,,,,,,,';xKOxoc,',,,,,,,,''l0Kkol;l00kdc,',,,,,,,,,.;kK0xo:'',,,',d0koc;'',,,,,,,,,,'
//,',;;;;;;;:oOkoc;'',,'':odll;,;;;;;;,,oOkdol,';;;;;;,,oOkoc:,,,'''.',;cxOdc:;;;;:c:,,;;,,okocclooo:'...',;;;:oOkdl:;;;;;;;,,lkkkkxl:;;;;;;;;:lOX0dl:':kOkxxl:;;;;;;;;;:dKKkoc;',;;;,;xKOdc;,,;;;;;;;;;;'
//,',;;;;;,,;dOxol:,,;;,';dxol;',;;;;;,,dKOxoc,,,;;;;;',dOkdl:'.'''',,;;cxOd:'.'''''..',,,,oko:;:odkdc;,,,;;;;;oOOdl:,,;;;;;,',cxxkO0OxollllldOKKOdl:'.'cdxkOOkdlcccccldOK0koc;'',;;;,;kX0xl:,,;;;;;;;;;;'
//,',,,,,,,,;dOkxdc,,,,,':xkdo:',,,,,,,;xX0kdl,',,,,,,',x0Oxoc,',,,,,,,,ckOd:'',,,,'',;;,',dkd:..:ldkOkd:,,,,,;dOOdo:,,,,,,,,'.';codkO0KKKKKK0Okdl:,'.''';codkO0K0000KKK0koc;'.',,,,,':OX0kdc,',,,,,,,,,,'
//,''''''''';dOOkxc'''''':kkdo:''''''',ckKOxkd:'''''''':kKOxdo;'''''''';d0Oxdlcccclldxo;'';xOxc'..;ldO00Oo;,'';d0Oxoc,,'''''''''..,;clloddddolc:,'...''''..,:clodxxxxxolc:,'...'''''':dO0kxkxl,'''''''',,'
//,''''''''';x0Okkc''''''ckOxd:..'''..;lollcllc,.'''..,coolcll:,'.'..',lddollooooodddo:'.,lkkdl;'..,cddxkkxc,';d00xoc,'''''''''''..,,..''''''.......''''''.....',,,,,,'......''''''.';cc:;;:::,'.'''''',,'
//,'........:x00Okc.....'cOOkxc'..........................................................',''''.....,,,,;;,..;xK0kxdocccllllllllldx:................................................................',,,'
//'''.......cO00OOc.....'cxdddo;'.............................................................................:kK0kxkkOOOO00000000Od;..............................................................',,,,:d
//l,''....,:okxddxc......',''''..............................................................................,oOkxdddddddddddddddddo;.............................................................',,':dKW
//Nx:'''..',,'''','',,',,''''................................................................................';,,,,,,,,,,,,,,,,,,,,,............................................................',,,:xKWMM
//MW0l,'''''''''''',,,''':l;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.......................''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',:xKWMMMM
//MMWKc.............;dkdd0Nk;....................................................................................................................................................................c0WMMMMMM


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface LootInterface {
	function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface MLootInterface {
	function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface GAInterface {
	function ownerOf(uint256 tokenId) external view returns (address owner);
	function getWeapon(uint256 tokenId) external view returns (string memory);
	function getChest(uint256 tokenId) external view returns (string memory);
	function getHead(uint256 tokenId) external view returns (string memory);
	function getWaist(uint256 tokenId) external view returns (string memory);
	function getFoot(uint256 tokenId) external view returns (string memory);
	function getHand(uint256 tokenId) external view returns (string memory);
	function getNeck(uint256 tokenId) external view returns (string memory);
	function getRing(uint256 tokenId) external view returns (string memory);
}

contract HyperLoot is ERC721, IERC2981, ReentrancyGuard, Ownable{
	using Counters for Counters.Counter;

	// Project info
	uint256 public constant TOTAL_SUPPLY = 20000;
	uint256 public constant MINT_PRICE = 0.05 ether;

	// Royalty
	uint256 public royaltyPercentage;
	address public royaltyAddress;
	
	// Contrat's state
	bool public isPresaleActive = false;
	bool public isPublicSaleActive = false;
	bool public isLootPublicSaleActive = false;
	bool private _isSpecialSetMinted = false;
	string private _baseTokenURI;
	bytes32 public hyperlistMerkleRoot;

	// 3 different types of bag used to mint HyperLoot
	uint16 private constant _lootType = 0;
	uint16 private constant _mlootType = 1;
	uint16 private constant _gaType = 2;

	// Total 5 group = loot, hyperlist, mloot, ga, special set
	// Supply for different groups
	uint16 private constant _supplyLoot = 7776;
	uint16 private constant _supplyGiveaway = 224;
	uint16 private constant _supplyGA = 400;
	uint16 private constant _supplySpecialSet = 7;
	uint16 private constant _supplyMLoot = 11593;

	// Token count for different groups
	uint16 private _tokenIdStartMLoot = 8001;
	uint16 private _tokenIdStartGA = 19594;
	uint16 private _tokenIdStartSpecialSet = 19994;
	Counters.Counter private _countTokenLoot;
	Counters.Counter private _countTokenMLoot;
	Counters.Counter private _countTokenGA;

	// Specific address claimable info
	mapping(address => bool) private _hyperlist;
	mapping(address => uint256) private _giveawayList;
	mapping(address => bool) private _claimedHyperlist;

	// Claimed mloot and ga states
	mapping(uint256 => bool) private _claimedMLoot;
	mapping(uint256 => bool) private _claimedGA;

	// Loot Contract
	address private lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
	LootInterface lootContract = LootInterface(lootAddress);

	// More Loot Contract
	address private mlootAddress = 0x1dfe7Ca09e99d10835Bf73044a23B73Fc20623DF;
	MLootInterface mlootContract = MLootInterface(mlootAddress);

	// Genesis Adventurer Contract
	address private gaAddress = 0x8dB687aCEb92c66f013e1D614137238Cc698fEdb;
	GAInterface gaContract = GAInterface(gaAddress);

	// TokenType = [Loot, MLoot, GA, Giveaway]
	event HyperLootMinted(address indexed to, uint256 indexed id, uint256 fromTokenType, uint256 fromTokenId, uint8[4] traits);

	constructor() ERC721("HyperLoot", "HLOOT") {}

	// ————————————————— //
	// ——— Modifiers ——— //
	// ————————————————— //

	modifier presaleActive() {
		require(isPresaleActive, "PRESALE_NOT_ACTIVE");
		_;
	}

	modifier publicSaleActive() {
		require(isPublicSaleActive, "PUBLIC_SALE_NOT_ACTIVE");
		_;
	}

	modifier lootPublicSaleActive() {
		require(isLootPublicSaleActive, "LOOT_PUBLIC_SALE_NOT_ACTIVE");
		_;
	}

	modifier isPaymentValid(uint256 amount) {
		// Max 20 HyperLoot per trasaction
		require(amount <= 20, "OVER_20_MAX_LIMIT");
		require((MINT_PRICE * amount) <= msg.value, "WRONG_ETHER_VALUE");
		_;
	}

	modifier isGiveawaySupplyAvailable(uint256 lootId) {
		require(lootId > 7777 && lootId < 8001, "TOKEN_ID_OUT_OF_RANGE");
		// Only allowed to mint specific loot id
		require(_giveawayList[msg.sender] == lootId, "ADDRESS_NOT_ELIGIBLE");
        _;
	}

	// —————————————————————————————————— //
	// ——— Public/Community Functions ——— //
	// —————————————————————————————————— //

	// Hodlers of Loot, GA; limit mloot hodlers to mint only 1 hyperloot if in hyperlist
	function mintPresale(uint256[] calldata bagIds, uint16[] calldata bagType, uint8[] calldata traits, bytes32[] calldata merkleProof) external payable
		nonReentrant
		presaleActive
		isPaymentValid(bagIds.length) {
			_checkTraitsCount(bagIds.length, bagType.length, traits.length);

			for (uint8 index = 0; index < bagIds.length; index++) {
				// traits = [face, eyes, bg, left]
				uint8 face = traits[index * 4];
				uint8 eyes = traits[index * 4 + 1];
				uint8 bg = traits[index * 4 + 2];
				uint8 left = traits[index * 4 + 3];
				_checkTraitsValid(face, eyes, bg, left);

				uint bagId = bagIds[index];
				if (bagType[index] == _lootType) {
					_checkLootOwner(bagId);

					_mintHyperLootEvent(msg.sender, bagId, _lootType, bagId, face, eyes, bg, left);
					_countTokenLoot.increment();
				} else if (bagType[index] == _mlootType) {
					// Check if address is in hyperlist
					_checkMerkleProof(merkleProof, hyperlistMerkleRoot, msg.sender);
					// Check if user already claimed hyperlist
					_checkHyperlistClaimed(msg.sender);
					// Check mLoot
					_checkMLootOwner(bagId);

					_mintHyperLootEvent(msg.sender, _tokenIdStartMLoot + _countTokenMLoot.current(), _mlootType, bagId, face, eyes, bg, left);
					_claimMLoot(bagId);
					_claimedHyperlist[msg.sender] = true;
				} else if (bagType[index] == _gaType) {
					_checkGASupply();
					_checkGAOwner(bagId);

					_mintHyperLootEvent(msg.sender, _tokenIdStartGA + _countTokenGA.current(), _gaType, bagId, face, eyes, bg, left);
					_claimGA(bagId);
				}
			}
	}

	// Hodlers of Loot, mLoot, GA can mint
	function mintPublic(uint256[] calldata bagIds, uint16[] calldata bagType, uint8[] calldata traits) external payable
		nonReentrant
		publicSaleActive
		isPaymentValid(bagIds.length) {
			_checkTraitsCount(bagIds.length, bagType.length, traits.length);

			for (uint8 index = 0; index < bagIds.length; index++) {
				// array format = [face, eyes, bg, left]
				uint8 face = traits[index * 4];
				uint8 eyes = traits[index * 4 + 1];
				uint8 bg = traits[index * 4 + 2];
				uint8 left = traits[index * 4 + 3];
				_checkTraitsValid(face, eyes, bg, left);

				uint bagId = bagIds[index];
				if (bagType[index] == _lootType) {
					_checkLootOwner(bagId);

					_mintHyperLootEvent(msg.sender, bagId, _lootType, bagId, face, eyes, bg, left);
					_countTokenLoot.increment();
				} else if (bagType[index] == _mlootType) {
					_checkMLootSupply();
					_checkMLootOwner(bagId);

					_mintHyperLootEvent(msg.sender, _tokenIdStartMLoot + _countTokenMLoot.current(), _mlootType, bagId, face, eyes, bg, left);
					_claimMLoot(bagId);
				} else if (bagType[index] == _gaType) {
					_checkGASupply();
					_checkGAOwner(bagId);

					_mintHyperLootEvent(msg.sender, _tokenIdStartGA + _countTokenGA.current(), _gaType, bagId, face, eyes, bg, left);
					_claimGA(bagId);
				}
			}
	}

	// Hodlers of mLoot, GA can mint; anyone can mint Loot
	function mintLootPublic(uint256[] calldata bagIds, uint16[] calldata bagType, uint8[] calldata traits) external payable
		nonReentrant
		lootPublicSaleActive
		isPaymentValid(bagIds.length) {
			_checkTraitsCount(bagIds.length, bagType.length, traits.length);

			for (uint8 index = 0; index < bagIds.length; index++) {
				// traits = [face, eyes, bg, left]
				uint8 face = traits[index * 4];
				uint8 eyes = traits[index * 4 + 1];
				uint8 bg = traits[index * 4 + 2];
				uint8 left = traits[index * 4 + 3];
				_checkTraitsValid(face, eyes, bg, left);

				uint bagId = bagIds[index];
				if (bagType[index] == _lootType) {
					_checkLoot(bagId);

					_mintHyperLootEvent(msg.sender, bagId, _lootType, bagId, face, eyes, bg, left);
					_countTokenLoot.increment();
				} else if (bagType[index] == _mlootType) {
					_checkMLootSupply();
					_checkMLootOwner(bagId);

					_mintHyperLootEvent(msg.sender, _tokenIdStartMLoot + _countTokenMLoot.current(), _mlootType, bagId, face, eyes, bg, left);
					_claimMLoot(bagId);
				} else if (bagType[index] == _gaType) {
					_checkGASupply();
					_checkGAOwner(bagId);

					_mintHyperLootEvent(msg.sender, _tokenIdStartGA + _countTokenGA.current(), _gaType, bagId, face, eyes, bg, left);
					_claimGA(bagId);
				}
			}
	}

	// Token ID 7778-8000; except 7836 & 7881
	function mintGiveaway(uint256 lootId, uint8 faceId, uint8 eyesId, uint8 backgroundId, uint8 leftHandId) external
		nonReentrant
		isGiveawaySupplyAvailable(lootId) {
		_checkTraitsValid(faceId, eyesId, backgroundId, leftHandId);
		_mintHyperLootEvent(msg.sender, lootId, _lootType, lootId, faceId, eyesId, backgroundId, leftHandId);
		_countTokenLoot.increment();
	}

	// Token ID 19,994 - 20,000
	function mintSpecialSet() external nonReentrant onlyOwner {
		require(!_isSpecialSetMinted, "SPECIAL_SET_ALREADY_CLAIMED");

		for (uint256 index = 0; index < _supplySpecialSet; index++) {
			_mintToken(msg.sender, _tokenIdStartSpecialSet + index);
		}

		_isSpecialSetMinted = true;
	}

	// ———————————————————————— //
	// ——— Helper Functions ——— //
	// ———————————————————————— //

	function _checkMerkleProof(bytes32[] calldata merkleProof, bytes32 root, address from) private pure {
		require(MerkleProof.verify(merkleProof, root, keccak256(abi.encodePacked(from))),"ADDRESS_NOT_ELIGIBLE");
	}

	function _checkHyperlistClaimed(address from) private view {
		require(!_claimedHyperlist[from], "ADDRESS_HYPERLIST_QUOTA_EXCEED");
	}

	function _checkTraitsCount(uint256 bagIds, uint256 bagType, uint256 traits) private pure {
		require(bagIds == bagType, "BAG_TYPE_LENGTH_MISMATCH");
		require(bagIds == traits / 4, "TRAIT_LENGTH_MISMATCH");
	}
 
	function _checkLootOwner(uint256 lootId) private view {
		_checkLoot(lootId);
		require(lootContract.ownerOf(lootId) == msg.sender, "MUST_OWN_TOKEN_ID");
	}

	function _checkLoot(uint256 lootId) private pure {
		// Token ID 1 - 8000; 7836 & 7881 has been minted by dom
		require(lootId < 7776 && lootId != 7836 && lootId != 7881, "LOOT_TOKEN_ID_OUT_OF_RANGE");
	}

	function _checkMLootOwner(uint256 mlootId) private view {
		// Token ID 8,001 - 18993
		require(mlootId > 8000, "MLOOT_TOKEN_ID_OUT_OF_RANGE");
		require(mlootContract.ownerOf(mlootId) == msg.sender, "MUST_OWN_TOKEN_ID");
		require(!_claimedMLoot[mlootId], "MLOOT_ALREADY_CLAIMED");
	}

	function _checkGAOwner(uint256 gaId) private view {
		require(gaContract.ownerOf(gaId) == msg.sender, "MUST_OWN_TOKEN_ID");
		require(!_claimedGA[gaId], "GA_ALREADY_CLAIMED");
		_checkLostMana(gaId);
	}

	function _checkMLootSupply() private view {
		require(_countTokenMLoot.current() < _supplyMLoot, "MLOOT_SOLD_OUT");
	}

	function _checkGASupply() private view {
		require(_countTokenGA.current() < _supplyGA, "GA_SOLD_OUT");
	}

	function _checkTraitsValid(uint8 faceId, uint8 eyesId, uint8 backgroundId, uint8 leftHandId) private pure {
		_checkFaceTrait(faceId);
		_checkEyesTrait(eyesId);
		_checkBackgroundTrait(backgroundId);
		_checkLeftHandTrait(leftHandId);
	}

	function _checkBackgroundTrait(uint8 backgroundId) private pure {
		// 18 type of background
		require(backgroundId >= 0 && backgroundId < 18, "BACKGROUND_TRAIT_OUT_OF_RANGE");
	}

	function _checkFaceTrait(uint8 faceId) private pure {
		// 26 type of face
		require(faceId >= 0 && faceId < 26, "FACE_TRAIT_OUT_OF_RANGE");
	}

	function _checkEyesTrait(uint8 eyesId) private pure {
		// 14 type of eyes
		require(eyesId >= 0 && eyesId < 14, "EYES_TRAIT_OUT_OF_RANGE");
	}

	function _checkLeftHandTrait(uint8 leftHandId) private pure {
		// 14 type of left hand; 0 = none
		require(leftHandId >= 0 && leftHandId < 14, "LEFT_HAND_TRAIT_OUT_OF_RANGE");
	}

	function _claimMLoot(uint256 mlootId) private {
		_countTokenMLoot.increment();
		_claimedMLoot[mlootId] = true;
	}

	function _claimGA(uint256 gaId) private {
		_countTokenGA.increment();
		_claimedGA[gaId] = true;
	}

	function _mintHyperLootEvent(address _to, uint256 _tokenId, uint256 _tokenType, uint256 _fromTokenId, uint8 faceIds, uint8 eyesIds, uint8 backgroundIds, uint8 leftHandIds) private {
		_mintToken(_to, _tokenId);
		emit HyperLootMinted(_to, _tokenId, _tokenType, _fromTokenId, [faceIds, eyesIds, backgroundIds, leftHandIds]);
	}

	function _mintToken(address _to, uint256 _tokenId) private {
		_safeMint(_to, _tokenId);
	}

	function _checkLostMana(uint256 bagId) private view {
		_checkLostManaItem(gaContract.getWeapon(bagId));
		_checkLostManaItem(gaContract.getChest(bagId));
		_checkLostManaItem(gaContract.getHead(bagId));
		_checkLostManaItem(gaContract.getWaist(bagId));
		_checkLostManaItem(gaContract.getFoot(bagId));
		_checkLostManaItem(gaContract.getHand(bagId));
		_checkLostManaItem(gaContract.getNeck(bagId));
		_checkLostManaItem(gaContract.getRing(bagId));
	}

	function _checkLostManaItem(string memory itemName) private pure {
		// Check if the item contains "Lost" in front
		bytes memory lostBytes = bytes ("Lost");
		bytes memory itemNameBytes = bytes (itemName);

		bool found = false;
		if (itemNameBytes[0] == lostBytes[0]
			&& itemNameBytes[1] == lostBytes[1]
			&& itemNameBytes[2] == lostBytes[2]
			&& itemNameBytes[3] == lostBytes[3]) {
				found = true;
			}

		require (!found, "BAG_CONTAINS_LOST_MANA");
	}

	// ——————————————————————————————- //
	// ——— Public Helper Functions ——— //
	// ——————————————————————————————- //

	function totalLootMinted() public view returns (uint256) {
		return _countTokenLoot.current();
	}

	function totalMLootMinted() public view returns (uint256) {
		return _countTokenMLoot.current();
	}

	function totalGAMinted() public view returns (uint256) {
		return _countTokenGA.current();
	}
	
	function totalSupply() public view returns (uint256) {
		return _countTokenLoot.current() + _countTokenMLoot.current() + _countTokenGA.current() + _supplySpecialSet;
	}

	function isLootClaimed(uint256 lootId) public view returns (bool) {
		return _exists(lootId);
	}

	function isMLootClaimed(uint256 mlootId) public view returns (bool) {
		return _claimedMLoot[mlootId];
	}

	function isGAClaimed(uint256 gaId) public view returns (bool) {
		return _claimedGA[gaId];
	}

	// ————————————————————————————— //
	// ——— Admin/Owner Functions ——— //
	// ————————————————————————————— //

	function setPresale(bool saleState) external onlyOwner {
		isPresaleActive = saleState;
	}

	function setPublicSale(bool saleState) external onlyOwner {
		isPublicSaleActive = saleState;
		isPresaleActive = false;
	}

	function setMerkleRoot(bytes32 root) external onlyOwner {
		hyperlistMerkleRoot = root;
	}

	function setGiveaway(address[] calldata addresses, uint256[] calldata lootIds) external onlyOwner {
		for (uint256 i = 0; i < addresses.length; i++) {
			_giveawayList[addresses[i]] = lootIds[i];
		}
	}

	function setLootPublicSale() external onlyOwner {
		isLootPublicSaleActive = true;
	}

	function setBaseURI(string memory baseURI) public onlyOwner {
		_baseTokenURI = baseURI;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
		return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
	}

	function setRoyalty(uint256 percentage, address receiver) external onlyOwner {
		royaltyPercentage = percentage;
		royaltyAddress = receiver;
	}

	function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royalty) {
		uint256 royaltyAmount = (salePrice * royaltyPercentage) / 10000;
		return (royaltyAddress, royaltyAmount);
	}

	function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}