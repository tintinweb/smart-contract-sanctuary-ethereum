// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";


contract DAO is Auction {
    struct Vote {
        address author;
        string comment;
        uint256 createdTime;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct Proposal {
        address author;
        string proposal;
        uint256 amount;
        uint256 createdTime;
        uint256 commentsCount;
        uint256 compatsCount;
        uint256 votersCount;
        uint256 upVotes;
        uint256 downVotes;
        uint256 endTime;
        bool finished;
    }

    uint256 public proposalDuration;
    uint256 public minBalanceForProposalCreation;
    uint256 public minBalanceForVoting;

    Proposal[] public proposals;
    Compatibility[][] public compatibilities;
    Vote[][] public comments;
    address[][] public voters;
    mapping(address => Vote)[] public votes;

    uint256 public proposalsCount;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 mutagenFrequency_,
        uint256 autoMintInterval_,
        uint256 creatorRoyalty_,
        uint256 treasureRoyalty_,
        uint256 proposalDuration_,
        uint256 minBalanceForProposalCreation_,
        uint256 minBalanceForVoting_
    ) Auction(name_, symbol_, baseURI_, mutagenFrequency_, autoMintInterval_, creatorRoyalty_, treasureRoyalty_) {
        proposalDuration = proposalDuration_;
        minBalanceForProposalCreation = minBalanceForProposalCreation_;
        minBalanceForVoting = minBalanceForVoting_;
    }

    function createProposal(
        string memory proposal,
        uint256 amount,
        Compatibility[] memory compats
    ) public virtual {
        require(owner() == _msgSender() || balanceOf(_msgSender()) >= minBalanceForProposalCreation, "D1");

//        for (uint256 i = 0; i < proposals.length; i++) {
//            if (!proposals[i].finished && block.timestamp >= proposals[i].endTime) {
//                finishProposal(i);
//            }
//        }

        proposals.push();
        compatibilities.push();
        comments.push();
        votes.push();
        voters.push();

        Proposal storage p = proposals[proposalsCount];
        p.author = _msgSender();
        p.proposal = proposal;
        p.amount = amount;
        p.createdTime = block.timestamp;
        p.endTime = block.timestamp + proposalDuration;
        p.compatsCount = compats.length;

        for (uint256 i = 0; i < compats.length; i++) {
            compatibilities[proposalsCount].push(compats[i]);
        }

        proposalsCount += 1;
    }

    function _validProposalIdx(uint256 proposalIdx) internal virtual {
        require(proposalIdx < proposalsCount, "D2");
    }

    modifier validProposalIdx(uint256 proposalIdx) virtual {
        _validProposalIdx(proposalIdx);
        _;
    }

    modifier proposalNotFinished(uint256 proposalIdx) virtual {
        require(!proposals[proposalIdx].finished, "D3");
        _;
    }

    function vote(
        uint256 proposalIdx,
        string memory comment,
        bool value
    ) public virtual validProposalIdx(proposalIdx) proposalNotFinished(proposalIdx) {
        uint256 _votes = balanceOf(_msgSender());

        Proposal storage p = proposals[proposalIdx];

        require(block.timestamp < p.endTime, "D7");
        require(owner() == _msgSender() || _votes >= minBalanceForVoting, "D4");

        Vote storage v = votes[proposalIdx][_msgSender()];

        require(v.author == address(0), "D5");

        if (_votes == 0 && owner() == _msgSender()) {
            _votes = 1;
        }

        if (value) {
            p.upVotes += _votes;
            v.upVotes = _votes;
        } else {
            p.downVotes += _votes;
            v.downVotes = _votes;
        }

        voters[proposalIdx].push(_msgSender());

        p.votersCount++;

        v.author = _msgSender();
        v.comment = comment;
        v.createdTime = block.timestamp;

        if (bytes(comment).length > 0) {
            comments[proposalIdx].push(v);
            p.commentsCount += 1;
        }

        // Add long term randomness
        _randint(block.timestamp);
    }

    function genesis() external virtual {
        if (seeds.length == 0) {
            _genTraits();
        }
    }

    function finishProposal(uint256 proposalIdx) public virtual validProposalIdx(proposalIdx) proposalNotFinished(proposalIdx) {
        Proposal storage p = proposals[proposalIdx];
        require((owner() == _msgSender() && p.amount == 0) || block.timestamp >= p.endTime, "D6");
        p.finished = true;

        if (p.downVotes >= p.upVotes) {
            return;
        }

        Compatibility[] storage compats = compatibilities[proposalIdx];
        uint256 key;
        uint256 cid;
        for (uint256 i = 0; i < compats.length; i++) {
            Compatibility storage c = compats[i];
            cid = allCompatibilities.length;
            allCompatibilities.push(c);
            key = uint256(keccak256(abi.encodePacked(c.trait, c.value, c.variation, c.baseTrait)));
            CompatibilityWithCid[] storage cwcs = compatsMap[key];
            cwcs.push();
            CompatibilityWithCid storage cwc = cwcs[cwcs.length - 1];
            cwc.baseTrait = c.baseTrait;
            cwc.baseValue = c.baseValue;
            cwc.baseVariation = c.baseVariation;
            cwc.compatsEnabled = c.compatsEnabled;
            cwc.compatible = c.compatible;
            cwc.cid = cid;
            _ensureVariation(c.baseTrait, c.baseValue, c.baseVariation);
            _ensureVariation(c.trait, c.value, c.variation);
        }

        if (p.amount > treasureAmount) {
            balances[p.author] += treasureAmount;
            treasureAmount = 0;
        } else {
            balances[p.author] += p.amount;
            treasureAmount -= p.amount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./NFT.sol";
import "./Traits.sol";


contract Auction is NFT {
    struct _Auction {
        uint256 minBid;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
        uint256 maxBidsCount;
        uint256 bidsCount;
    }

    uint256 public autoMintInterval;
    uint256 public creatorRoyalty;
    uint256 public treasureRoyalty;
    uint256 public treasureAmount;

    mapping(uint256 => _Auction) public auctions;
    mapping(address => uint256) public balances;

    mapping(uint256 => uint256) public lastPrice;
    uint256 public sold;
    uint256 public lastPricesSum;
    uint256 public lastAuctionTokenId;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 mutagenFrequency_,
        uint256 autoMintInterval_,
        uint256 creatorRoyalty_,
        uint256 treasureRoyalty_
    ) NFT(name_, symbol_, baseURI_, mutagenFrequency_) {
        autoMintInterval = autoMintInterval_;
        creatorRoyalty = creatorRoyalty_;
        treasureRoyalty = treasureRoyalty_;
    }

    function auctionStarted(uint256 tokenId) internal view virtual returns (bool) {
        return auctions[tokenId].endTime > 0;
    }

    function auctionFinished(uint256 tokenId) internal view virtual returns (bool) {
        _Auction storage auction = auctions[tokenId];
        return block.timestamp >= auction.endTime || (auction.maxBidsCount > 0 && auction.bidsCount >= auction.maxBidsCount);
    }

    function _auctionStart(uint256 tokenId, uint256 duration, uint256 minBid, uint256 maxBidsCount) internal virtual {
        auctions[tokenId].minBid = minBid;
        auctions[tokenId].endTime = block.timestamp + duration;
        auctions[tokenId].maxBidsCount = maxBidsCount;
    }

    function auctionStart(uint256 tokenId, uint256 duration, uint256 minBid, uint256 maxBidsCount) external virtual {
        require(!auctionStarted(tokenId), "A2");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "A5");
        _auctionStart(tokenId, duration, minBid, maxBidsCount);
    }

    function auctionBid(uint256 tokenId, uint256 bid) external payable virtual {
        bool startedAndFinished = _exists(lastAuctionTokenId) &&
            ownerOf(lastAuctionTokenId) == address(this) &&
            auctionStarted(lastAuctionTokenId) &&
            auctionFinished(lastAuctionTokenId);
        bool notExistsOrFinished = !_exists(lastAuctionTokenId) || (ownerOf(lastAuctionTokenId) != address(this)) || startedAndFinished;
        if (tokenId == tokenIdCounter && (tokenIdCounter == 0 || notExistsOrFinished)) {
            if (startedAndFinished) {
                auctionFinish(lastAuctionTokenId);
            }

            lastAuctionTokenId = tokenIdCounter;
            _mintWithTraits(address(this));
            _auctionStart(lastAuctionTokenId, autoMintInterval, 0, _randint(totalSupply() == 0 ? 1 : totalSupply()) == 0 ? 1 : 0);
        }

        require(auctionStarted(tokenId), "A14");
        require(!auctionFinished(tokenId), "A4");
        require(!_isApprovedOrOwner(_msgSender(), tokenId), "A6");

        _Auction storage auction = auctions[tokenId];

        require(_msgSender() != auction.highestBidder, "A7");

        uint256 newBid = bid > msg.value ? bid : msg.value;

        require(newBid >= auction.minBid, "A8");
        require(auction.highestBidder == address(0) || newBid > auction.highestBid, "A9");

        uint256 getFromBalance = newBid - msg.value;

        require(balances[_msgSender()] >= getFromBalance, "A10");

        balances[auction.highestBidder] += auction.highestBid;

        auction.bidsCount += 1;
        auction.highestBidder = _msgSender();
        auction.highestBid = newBid;
        balances[_msgSender()] -= getFromBalance;

        if (auctionFinished(tokenId)) {
            auctionFinish(tokenId);
        }
    }

    function auctionFinish(uint256 tokenId) public virtual {
        require(auctionStarted(tokenId), "A15");
        require(_isApprovedOrOwner(_msgSender(), tokenId) || auctionFinished(tokenId), "A11");

        _Auction storage auction = auctions[tokenId];

        bool firstSale = ownerOf(tokenId) == address(this);

        if (auction.highestBidder != address(0)) {
            uint256 creatorRoyaltyValue = auction.highestBid * creatorRoyalty / 1000;
            uint256 treasureRoyaltyValue = auction.highestBid * treasureRoyalty / 1000;
            uint256 withdrawValue = auction.highestBid - creatorRoyaltyValue - treasureRoyaltyValue;

            if (auction.highestBid > 0) {
                if (lastPrice[tokenId] == 0) {
                    sold += 1;
                } else {
                    lastPricesSum -= lastPrice[tokenId];
                }
                lastPricesSum += auction.highestBid;
                lastPrice[tokenId] = auction.highestBid;
            }

            balances[owner()] += creatorRoyaltyValue;
            treasureAmount += treasureRoyaltyValue;

            if (firstSale) {
                treasureAmount += withdrawValue;
            } else {
                balances[ownerOf(tokenId)] += withdrawValue;
            }

            _safeTransfer(ownerOf(tokenId), auction.highestBidder, tokenId, "");
        } else if (firstSale) {
            _burn(tokenId);
        }

        delete auctions[tokenId];
    }

    function auctionWithdraw(address to, uint256 amount) external virtual {
        require(amount > 0, "A12");
        require(balances[_msgSender()] >= amount, "A13");

        // Add long term randomness
        _randint(block.timestamp);

        balances[_msgSender()] -= amount;
        payable(to).transfer(amount);
    }

    function onSaleTokenIds() public view virtual returns (uint256[] memory){
        uint256 n;
        for (uint256 i; i < tokenIdCounter; i++) {
            if (auctionStarted(i) && !auctionFinished(i)) {
                n++;
            }
        }
        uint256 j;
        uint256[] memory ids = new uint256[](n);
        for (uint256 i; i < tokenIdCounter; i++) {
            if (auctionStarted(i) && !auctionFinished(i)) {
                ids[j] = i;
                j++;
            }
        }
        return ids;
    }

//    function auctionAvgMarketPrice() public view virtual returns (uint256){
//        return sold == 0 ? 0 : lastPricesSum / sold;
//    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./Traits.sol";


contract NFT is ERC721, ERC721Enumerable, ERC721Burnable, Traits {
    uint256 public tokenIdCounter;
    string public baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 mutagenFrequency_
    ) ERC721(name_, symbol_) Traits(mutagenFrequency_) {
        baseURI = baseURI_;
    }

    function _mintWithTraits(address to) internal {
        _genTraits();
        _safeMint(to, tokenIdCounter);
        tokenIdCounter++;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURI;
    }

    function mutate(uint256 tokenId1, uint256 tokenId2) external virtual {
        require(ownerOf(tokenId1) == _msgSender(), "N2");
        require(ownerOf(tokenId2) == _msgSender(), "N3");

        _mutate(tokenId1, tokenId2);

        _safeMint(_msgSender(), tokenIdCounter);
        tokenIdCounter++;

        _burn(tokenId1);
        _burn(tokenId2);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";


contract Traits is Ownable {
    string private constant randomTrait = "?";
    uint256 private constant MAXINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 public mutagenFrequency;

    struct Compatibility {
        string trait;
        string value;
        string variation;
        string baseTrait;
        string baseValue;
        string baseVariation;
        bool compatsEnabled;
        bool compatible;
    }

    struct CompatibilityWithCid {
        string baseTrait;
        string baseValue;
        string baseVariation;
        bool compatsEnabled;
        bool compatible;
        uint256 cid;
    }

    struct Trait {
        string trait;
        string value;
        string variation;
    }

    Compatibility[] internal allCompatibilities;
    mapping(uint256 => CompatibilityWithCid[]) internal compatsMap;
    uint256[] internal seeds;
    uint256[] internal cids;

    uint256 internal _seed;

    mapping(string => bool) traitsExists;
    mapping(string => mapping(string => bool)) valuesExists;
    mapping(string => mapping(string => mapping(string => bool))) variationsExists;

    string[] traits;
    mapping(string => string[]) values;
    mapping(string => mapping(string => string[])) variations;

    uint256[] public hueBg;
    uint256[] public hue;

    mapping(uint256 => mapping(string => string[])) internal constraints;
    mapping(uint256 => bool) internal isCreature;

    constructor(uint256 mutagenFrequency_) {
        _seed = block.timestamp;
        mutagenFrequency = mutagenFrequency_;
    }

    function _requireNotEmpty(string memory arg) internal virtual {
        require(bytes(arg).length > 0, 'T7');
    }

    function _randint(uint256 range) internal virtual returns (uint256) {
        // I have to make it predictable T_T
        // If it depended on block.timestamp or block.difficulty,
        // then we would constantly experience difficulties with
        // correct gas estimation.

        // In fact, true randomness persists in the long run
        // due to the unpredictability of traits generated by DAO.

        _seed = uint256(keccak256(abi.encodePacked(_seed, range)));
        return _seed % range;
    }

    function _randint2(uint256 seed, uint256 seed2) internal pure virtual returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, seed2)));
    }

    function equals(string memory a, string memory b) internal pure returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }

    function _genTraits() internal virtual {
        seeds.push(_seed);
        cids.push(allCompatibilities.length);
        hueBg.push(_randint(360));
        hue.push(_randint(360));
    }

    function _checkCompat(string storage trait, string storage value, string storage variation, uint256 cid, Trait[] memory ts, uint256 tsn) internal view virtual returns (bool) {
        for (uint256 ti; ti < tsn; ti++) {
            Trait memory ct = ts[ti];
            bool ce;
            bool cmp;
            uint256 key = uint256(keccak256(abi.encodePacked(trait, value, variation, ct.trait)));
            CompatibilityWithCid[] storage _compats = compatsMap[key];
            for (uint256 ci; ci < _compats.length; ci++) {
                CompatibilityWithCid storage c = _compats[ci];
                if (c.cid >= cid) {
                    break;
                }
                ce = c.compatsEnabled;
                if (equals(ct.value, c.baseValue) && equals(ct.variation, c.baseVariation)) {
                    cmp = c.compatible;
                }
            }
            if (ce && !cmp) {
                return false;
            }
        }
        return true;
    }

    function _getTrait(string[] storage allowedVals, string storage trait, uint256 tn, uint256 cid, Trait[] memory ts, uint256 tsn) internal view virtual returns (uint256, string storage, string storage) {
        uint256 j;
        uint256 k;
        uint256 n;
        string[] storage vals = allowedVals.length > 0 ? allowedVals : values[trait];
        for (; j < vals.length; j++) {
            string storage value = vals[j];
            for (k = 0; k < variations[trait][value].length; k++) {
                string storage variation = variations[trait][value][k];
                if (_checkCompat(trait, value, variation, cid, ts, tsn)) {
                    if (tn == n) {
                        return (n, value, variation);
                    }
                    n++;
                }
            }
        }
        return (n, trait, trait);
    }

    function _ensureVariation(
        string storage trait,
        string storage value,
        string storage variation
    ) internal virtual {
        if (bytes(trait).length == 0 || bytes(value).length == 0 || bytes(variation).length == 0) {
            return;
        }

        if (!traitsExists[trait]) {
            traitsExists[trait] = true;
            traits.push(trait);
        }

        if (!valuesExists[trait][value]) {
            valuesExists[trait][value] = true;
            values[trait].push(value);
        }

        if (!variationsExists[trait][value][variation]) {
            variationsExists[trait][value][variation] = true;
            variations[trait][value].push(variation);
        }
    }

    function _mutate(uint256 idx1, uint256 idx2) internal virtual {
        Trait[] memory traits1 = getTraits(idx1);
        Trait[] memory traits2 = getTraits(idx2);

        require(traits1.length + traits2.length > 2, "T5");

        uint256 _s = seeds[seeds.length - 1];
        uint256 _c = cids[cids.length - 1];
        uint256 _h = hue[hue.length - 1];
        uint256 _hb = hueBg[hueBg.length - 1];

        seeds.pop();
        cids.pop();
        hue.pop();
        hueBg.pop();

        _genTraits();

        uint256 idx = seeds.length - 1;
        uint256 i;

        for (i = 0; i < traits1.length; i++) {
            constraints[idx][traits1[i].trait].push(traits1[i].value);
        }
        for (i = 0; i < traits2.length; i++) {
            constraints[idx][traits2[i].trait].push(traits2[i].value);
        }
        for (i = 0; i < traits.length; i++) {
            string[] storage vals = constraints[idx][traits[i]];
            if (vals.length > 0 && (bytes(vals[0]).length == 0 || (vals.length == 2 && bytes(vals[1]).length == 0))) {
                delete constraints[idx][traits[i]];
            }
        }

        isCreature[idx] = true;

        seeds.push(_s);
        cids.push(_c);
        hue.push(_h);
        hueBg.push(_hb);
    }

    function getTraits(uint256 idx) public view virtual returns (Trait[] memory) {
        uint256 seed = seeds[idx];

        if (!isCreature[idx] && (seed % mutagenFrequency == 0)) {
            Trait[] memory _ts = new Trait[](1);
            seed = _randint2(seed, idx);
            _ts[0].trait = traits[seed % traits.length];
            return _ts;
        }

        Trait[] memory ts = new Trait[](traits.length);
        uint256 tsn = 0;

        uint256 cid = cids[idx];
        uint256 i;
        uint256 tn;
        string storage value;
        string storage variation;

        for (; i < traits.length; i++) {
            string storage trait = traits[i];
            string[] storage allowedVals = constraints[idx][trait];
            (tn, value, variation) = _getTrait(allowedVals, trait, MAXINT, cid, ts, tsn);
            if (tn == 0) {
                continue;
            }
            seed = _randint2(seed, tn);
            (tn, value, variation) = _getTrait(allowedVals, trait, seed % tn, cid, ts, tsn);
            ts[tsn].trait = trait;
            ts[tsn].value = value;
            ts[tsn].variation = variation;
            tsn++;
        }

        Trait[] memory retTraits = new Trait[](tsn);
        for (i = 0; i < tsn; i++) {
            retTraits[i] = ts[i];
        }
        return retTraits;
    }

    function getCompats() external view virtual returns (Compatibility[] memory) {
        return allCompatibilities;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol) - optimized by compiled size

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _onlyOwner() internal view {
        require(owner() == _msgSender(), "O1");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "O2");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}