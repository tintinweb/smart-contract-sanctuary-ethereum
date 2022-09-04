//SPDX-License-Identifier: MIT

//   ____ ______ __  __  ____ ____   ____ __ __ ___  ___    ___  ___  ____ ____    ___   ____     ____ ____   ___    ___ ______  ___  __   
//  ||    | || | ||  || ||    || \\ ||    || || ||\\//||    ||\\//|| ||    || \\  // \\ ||       ||    || \\ // \\  //   | || | // \\ ||   
//  ||==    ||   ||==|| ||==  ||_// ||==  || || || \/ ||    || \/ || ||==  ||_// (( ___ ||==     ||==  ||_// ||=|| ((      ||   ||=|| ||   
//  ||___   ||   ||  || ||___ || \\ ||___ \\_// ||    ||    ||    || ||___ || \\  \\_|| ||___    ||    || \\ || ||  \\__   ||   || || ||__|
                                                                                                                                        
// (ASCII art font: Double, via https://patorjk.com/software/taag)

// Merge Fractal NFT developed for the Ethereum Merge event
// by David Ryan (drcoder.eth, @davidryan59 on Twitter)
// Check out some more of my fractal art at Nifty Ink!
// My artist page for niftymaestro.eth: https://nifty.ink/artist/0xbFAc61D1e22EFA9d37Fc3Ff36B9dff9655131F52

pragma solidity ^0.6.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
// Learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

import './SharedFnsAndData.sol';
import './FractalStrings.sol';


contract MergeFractal is ERC721, Ownable {

  // all ETH from NFT sales goes to https://app.0xsplits.xyz/accounts/0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9/
  address payable public constant recipient =
    payable(0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9);

  // ----------------------------------------------

  // // Local testnet setup
  // string internal constant NETWORK = 'TESTNET 12';
  // uint256 internal constant INITIAL_PRICE = 1000000 * 1000000000; // 0.001 ETH
  // uint256 internal constant INCREMENT_PRICE = 200000 * 1000000000; // 0.0002 ETH
  // uint256 internal constant INCREMENT_STEP = 2;
  // uint24 internal constant MINT_LIMIT = 5;

  // // Goerli test deployment(s)
  // string internal constant NETWORK = 'GOERLI TEST 14';
  // uint256 internal constant INITIAL_PRICE = 1000000 * 1000000000; // 0.001 ETH
  // uint256 internal constant INCREMENT_PRICE = 200000 * 1000000000; // 0.0002 ETH
  // uint256 internal constant INCREMENT_STEP = 1;
  // uint24 internal constant MINT_LIMIT = 2;

  // Mainnet deployment
  string internal constant NETWORK = 'Ethereum';
  uint256 internal constant INITIAL_PRICE = 1000000 * 1000000000; // 0.001 ETH
  uint256 internal constant INCREMENT_PRICE = 200000 * 1000000000; // 0.0002 ETH
  uint256 internal constant INCREMENT_STEP = 50; // increments at 51, 101, 151, 201...
  uint24 internal constant MINT_LIMIT = 5875;

  // ----------------------------------------------

  // Control placement of 4 sets of rotating lines
  uint8[4] internal sectionLineTranslates = [2, 4, 36, 38];

  // Random team to thank, looks up from core dev
  uint8 internal constant TEAM_ARRAY_LEN = 25;
  string[TEAM_ARRAY_LEN] internal teams = [
    'Independent', // hidden
    '0xSplits', // hidden
    'Akula',
    'EF DevOps',
    'EF Geth',
    'EF Ipsilon',
    'EF JavaScript',
    'EF Portal',
    'EF Protocol Support',
    'EF Research',
    'EF Robust Incentives Group',
    'EF Security',
    'EF Solidity',
    'EF Testing',
    'Erigon',
    'Ethereum Cat Herders',
    'Hyperledger Besu',
    'Lighthouse',
    'Lodestar',
    'Nethermind',
    'Prysmatic',
    'Quilt',
    'Status',
    'Teku',
    'TXRX'
  ];

  // Random subtitle
  uint8 internal constant SUBTITLE_ARRAY_LEN = 30;
  string[SUBTITLE_ARRAY_LEN] internal subtitles = [
    'Ethereum Merge September 2022',
    'TTD 58750000000000000000000',
    'Proof-of-stake consensus',
    'Environmentally friendly',
    'Energy consumption -99.95%',
    'Unstoppable smart contracts',
    'Sustainable and secure',
    'Global settlement layer',
    'World Computer',
    'Run your own node',
    'Permissionless',
    'TTD 5.875 * 10^22',
    'Run your own validator',
    'Neutral settlement layer',
    'Validators > Miners',
    'Decentralise Everything',
    'PoS > PoW',
    'Validate with 32 ETH',
    'The Flippening',
    'Fight for financial privacy by default',
    'TTD 2^19 * 5^22 * 47',
    'Build on Scaffold Eth',
    'Build with the Buidl Guidl',
    'Austin Griffith is Buidling',
    'Owocki and Gitcoin are coordinating',
    'Superphiz has decentralised everything',
    'Bankless is trustless',
    'Vitalik is clapping',
    'Vitalik is dancing',
    'Anthony Sassano is dancing'
  ];

  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  SharedFnsAndData sfad;
  FractalStrings fs;
  constructor(address sfadAddress, address fsAddress) public ERC721("MergeFractals", "MERGFRAC") {
    // Using 3 contracts since there was too much for 1 contract...
    sfad = SharedFnsAndData(sfadAddress);
    fs = FractalStrings(fsAddress);
  }

  mapping (uint256 => uint256) internal generator;
  mapping (uint256 => address) internal mintooor;

  function mintItem()
    public
    payable
    returns (uint256)
  {
    require(isMintingAllowed(), "MINT LIMIT REACHED"); 
    require(msg.value == getPriceNext(), "NEED TO SEND ETH");
    _tokenIds.increment();
    uint256 id = _tokenIds.current(); // previous mintCount + 1
    _mint(msg.sender, id);
    generator[id] = uint256(keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), id)));
    mintooor[id] = msg.sender;
    // Send proceeds of NFT sales to fixed recipient
    (bool success, ) = recipient.call{value: msg.value}("");
    require(success, "ETH TO RECIPIENT FAIL");
    return id;
  }

  // Query the mint limit
  function mintLimit() public pure returns (uint24) {
    return MINT_LIMIT;
  }

  // Query the current mint count
  function mintCount() public view returns (uint24) {
    return uint24(_tokenIds.current());
  }

  // Check if minting is allowed, and has not finished
  function isMintingAllowed() public view returns (bool) {
    return _tokenIds.current() < MINT_LIMIT;
  }

  // Linear increments of mint price at certain ids
  function getPriceById(uint256 id) public pure returns (uint256) {
    return INITIAL_PRICE + INCREMENT_PRICE * ((id - 1) / INCREMENT_STEP);
  }

  // Call this function before minting to get mint price
  function getPriceNext() public view returns (uint256) {
    return getPriceById(_tokenIds.current() + 1);
  }

  function getAttribute(string memory attribType, string memory attribValue, string memory suffix) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type": "',
      attribType,
      '", "value": "',
      attribValue,
      '"}',
      suffix
    ));
  }

  function getAllAttributes(uint256 id) public view returns (string memory) {
    uint256 gen = generator[id];
    return string(abi.encodePacked(
      '[',
      getAttribute("Dev", getCoreDevName(id), ','),
      getAttribute("Team", getTeamName(id), ','),
      getAttribute("Subtitle", getSubtitle(gen), ','),
      getAttribute("Style", fs.styleText(gen), ','),
      getAttribute("Dropouts", sfad.uint2str(fs.countDropouts(gen)), ','),
      getAttribute("Twists", sfad.uint2str(fs.getTwistiness(gen)), ','),
      getAttribute("Duration", sfad.uint2str(fs.getAnimDurS(gen)), ','),
      getAttribute("Monochrome", sfad.isMonochrome(gen) ? 'Yes' : 'No', ']')
    ));
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "not exist");
    string memory name = string(abi.encodePacked(NETWORK, ' Merge Fractal #',id.toString()));
    string memory description = string(abi.encodePacked(
      'This ',
      NETWORK,
      ' Merge Fractal is to thank ',
      getCoreDevName(id),
      '!'
    ));
    string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(bytes(abi.encodePacked(
        '{"name":"',
        name,
        '", "description":"',
        description,
        '", "external_url":"https://ethereum-merge-fractals.surge.sh/token/',
        id.toString(),
        '", "attributes": ',
        getAllAttributes(id),
        ', "owner":"',
        sfad.toHexString(uint160(ownerOf(id)), 20),
        '", "image": "data:image/svg+xml;base64,',
        image,
        '"}'
      )))
    ));
  }

  function generateSVGofTokenById(uint256 id) public view returns (string memory) {
    return string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));
  }

  function renderDisk(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<circle fill="',
      sfad.getRGBA(gen, 3, "1"),
      '" cx="200" cy="200" r="200"/>'
    ));
  }

  function getLinesTransform(uint8 arraySection) internal view returns (string memory) {
    uint16 num1 = sectionLineTranslates[arraySection];
    return string(abi.encodePacked(
      ' transform="translate(',
      sfad.uint2str(num1),
      ' ',
      sfad.uint2str(num1),
      ') scale(0.',
      sfad.uint2str(200 - num1),
      ')"'
    ));
  }

  // Uses 6 random bits per line set / section
  function renderLines(uint256 gen, uint8 arraySection, string memory maxAngleText) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; ',
      maxAngleText,
      ' 200 200; 0 200 200"',
      sfad.getDurText(gen, arraySection),
      ' repeatCount="indefinite"/><path fill="none" stroke-linecap="round" stroke="',
      sfad.getRGBA(gen, arraySection, "0.90"),
      '" stroke-width="9px"',
      sfad.getLinesPath(),
      getLinesTransform(arraySection),
      '/></g>'
    ));
  }

  function renderDiskAndLines(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      renderDisk(gen),
      renderLines(gen, 0, "-270"),
      renderLines(gen, 1, "270"),
      renderLines(gen, 2, "-180"),
      renderLines(gen, 3, "180")
    ));
  }

  function renderBorder(uint256 gen) internal view returns (string memory) {
    string memory rgba0 = sfad.getRGBA(gen, 0, "0.9");
    return string(abi.encodePacked(
      '<circle r="180" stroke-width="28px" stroke="',
      sfad.getRGBA(gen, 3, "0.8"),
      '" fill="none" cx="200" cy="200"/><circle r="197" stroke-width="6px" stroke="',
      rgba0,
      '" fill="none" cx="200" cy="200"/><circle r="163" stroke-width="6px" stroke="',
      rgba0,
      '" fill="none" cx="200" cy="200"/>'
    ));
  }

  function getCoreDevIdx(uint256 id) internal view returns (uint8 idx) {
    return sfad.getUint8(generator[id], 0, 8) % sfad.getCoreDevArrayLen();
  }

  function getTeamIdx(uint256 id) internal view returns (uint8 idx) {
    return sfad.getCoreDevTeamIndex(getCoreDevIdx(id));
  }

  function getCoreDevName(uint256 id) internal view returns (string memory) {
    return sfad.getCoreDevName(getCoreDevIdx(id));
  }

  function getTeamName(uint256 id) internal view returns (string memory) {
    return teams[getTeamIdx(id)];
  }

  function getCoreDevAndTeamText(uint256 id) internal view returns (string memory) {
    string memory teamText = string(abi.encodePacked(' / ', getTeamName(id)));
    if (getTeamIdx(id) < 2) { // If team = Individual or 0xSplits, don't display team
      teamText = '';
    }
    return string(abi.encodePacked(
      getCoreDevName(id),
      teamText
    ));   
  }

  // Earlier subtitles in the array are common. Later ones are increasingly rare.
  function getSubtitle(uint256 gen) internal view returns (string memory) {
    uint8 rand1 = sfad.getUint8(gen, 172, 5) % SUBTITLE_ARRAY_LEN;
    uint8 rand2 = sfad.getUint8(gen, 177, 5) % SUBTITLE_ARRAY_LEN;
    uint8 idx = (rand1 < rand2) ? rand1 : rand2; // min function 
    return subtitles[idx];
  }

  function renderText(uint256 id) internal view returns (string memory) {
    uint256 gen = generator[id];
    return string(abi.encodePacked(
      '<defs><style>text{font-size:15px;font-family:Helvetica,sans-serif;font-weight:900;fill:',
      sfad.getRGBA(gen, 0, "1"),
      ';letter-spacing:1px}</style><path id="textcircle" fill="none" stroke="rgba(255,0,0,0.5)" d="M 196 375 A 175 175 270 1 1 375 200 A 175 175 90 0 1 204 375" /></defs>',
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 360 200 200" dur="120s" repeatCount="indefinite"/><text><textPath href="#textcircle">/ ',
      NETWORK,
      ' Merge Fractal #',
      sfad.uint2str(id),
      ' / ',
      getCoreDevAndTeamText(id),
      ' / ',
      getSubtitle(gen),
      ' / Minted by ',
      sfad.toHexString(uint160(mintooor[id]), 20),
      '♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦</textPath></text></g>'
    ));  
  }

  function renderTokenById(uint256 id) public view returns (string memory) {
    uint256 gen = generator[id];
    return string(abi.encodePacked(
      renderDiskAndLines(gen),
      renderBorder(gen),
      renderText(id),
      fs.renderEthereums(gen)
    ));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return _tokenOwners.contains(tokenId);
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
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
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// Mainnet 1

contract SharedFnsAndData {

  // Divide by 10000 and use as an interpolation factor
  uint8 internal constant INTERP_LEN = 6;
  uint16[INTERP_LEN] internal interpolationCurve10k = [0,0,5000,10000,10000,0];

  uint16[32] internal durations = [31,53,73,103,137,167,197,233,37,59,79,107,139,173,199,239,41,61,83,109,149,179,211,241,43,67,89,113,151,181,223,253];

  // Control colour randomisations (4 colours are used throughout)
  uint8[4] internal sectionColStartBits = [24, 30, 36, 42]; // 4 sections, each uses 3 bits for colour, 3 bits for duration

  // Control colours that are used in the NFT
  uint8[32] internal colsR = [0,26,80,0,0,40,0,40,76,102,230,0,0,170,0,85,153,179,230,0,230,160,80,240,230,255,255,196,196,255,128,255];
  uint8[32] internal colsG = [0,26,0,70,0,35,35,0,76,102,0,200,0,80,160,0,153,179,200,200,0,230,150,75,230,255,196,255,196,255,255,128];
  uint8[32] internal colsB = [0,26,0,0,90,0,45,45,76,102,0,0,255,0,90,180,153,179,0,255,255,90,255,170,230,255,196,196,255,128,255,255];

  bytes16 internal constant ALPHABET = '0123456789abcdef';
  string internal constant linesPath = ' d="M 11 1145 L 11 855 M 32 1251 L 32 749 M 53 1322 L 53 678 M 74 1379 L 74 621 M 96 1427 L 96 573 M 117 1469 L 117 531 M 138 1507 L 138 493 M 160 1542 L 160 458 M 181 1574 L 181 426 M 202 1603 L 202 397 M 223 1630 L 223 370 M 245 1655 L 245 345 M 266 1679 L 266 321 M 287 1701 L 287 299 M 309 1722 L 309 278 M 330 1742 L 330 258 M 351 1761 L 351 239 M 372 1778 L 372 222 M 394 1795 L 394 205 M 415 1811 L 415 189 M 436 1826 L 436 174 M 457 1840 L 457 160 M 479 1853 L 479 147 M 500 1866 L 500 134 M 521 1878 L 521 122 M 543 1889 L 543 111 M 564 1900 L 564 100 M 585 1910 L 585 90 M 606 1919 L 606 81 M 628 1928 L 628 72 M 649 1936 L 649 64 M 670 1944 L 670 56 M 691 1951 L 691 49 M 713 1958 L 713 42 M 734 1964 L 734 36 M 755 1970 L 755 30 M 777 1975 L 777 25 M 798 1979 L 798 21 M 819 1984 L 819 16 M 840 1987 L 840 13 M 862 1990 L 862 10 M 883 1993 L 883 7 M 904 1995 L 904 5 M 926 1997 L 926 3 M 947 1999 L 947 1 M 968 1999 L 968 1 M 989 2000 L 989 0 M 1011 2000 L 1011 0 M 1032 1999 L 1032 1 M 1053 1999 L 1053 1 M 1074 1997 L 1074 3 M 1096 1995 L 1096 5 M 1117 1993 L 1117 7 M 1138 1990 L 1138 10 M 1160 1987 L 1160 13 M 1181 1984 L 1181 16 M 1202 1979 L 1202 21 M 1223 1975 L 1223 25 M 1245 1970 L 1245 30 M 1266 1964 L 1266 36 M 1287 1958 L 1287 42 M 1309 1951 L 1309 49 M 1330 1944 L 1330 56 M 1351 1936 L 1351 64 M 1372 1928 L 1372 72 M 1394 1919 L 1394 81 M 1415 1910 L 1415 90 M 1436 1900 L 1436 100 M 1457 1889 L 1457 111 M 1479 1878 L 1479 122 M 1500 1866 L 1500 134 M 1521 1853 L 1521 147 M 1543 1840 L 1543 160 M 1564 1826 L 1564 174 M 1585 1811 L 1585 189 M 1606 1795 L 1606 205 M 1628 1778 L 1628 222 M 1649 1761 L 1649 239 M 1670 1742 L 1670 258 M 1691 1722 L 1691 278 M 1713 1701 L 1713 299 M 1734 1679 L 1734 321 M 1755 1655 L 1755 345 M 1777 1630 L 1777 370 M 1798 1603 L 1798 397 M 1819 1574 L 1819 426 M 1840 1542 L 1840 458 M 1862 1507 L 1862 493 M 1883 1469 L 1883 531 M 1904 1427 L 1904 573 M 1926 1379 L 1926 621 M 1947 1322 L 1947 678 M 1968 1251 L 1968 749 M 1989 1145 L 1989 855 "';
  uint8 internal constant CORE_DEV_ARRAY_LEN = 120;
  string[CORE_DEV_ARRAY_LEN] internal coreDevNames = ['Vitalik Buterin','0xSplits','Artem Vorotnikov','Parithosh Jayanthi','Rafael Matias','Guillaume Ballet','Jared Wasinger','Marius van der Wijden','Matt Garnett','Peter Szilagyi','Andrei Maiboroda','Jose Hugo de la cruz Romero','Paweł Bylica','Andrew Day','Gabriel','Holger Drewes','Jochem','Scotty Poi','Jacob Kaufmann','Jason Carver','Mike Ferris','Ognyan Genev','Piper Merriam','Danny Ryan','Tim Beiko','Trenton Van Epps','Aditya Asgaonkar','Alex Stokes','Ansgar Dietrichs','Antonio Sanso','Carl Beekhuizen','Dankrad Feist','Dmitry Khovratovich','Francesco d’Amato','George Kadianakis','Hsiao Wei Wang','Justin Drake','Mark Simkin','Proto','Zhenfei Zhang','Anders','Barnabé Monnot','Caspar Schwarz-Schilling','David Theodore','Fredrik Svantes','Justin Traglia','Tyler Holmes','Yoav Weiss','Alex Beregszaszi','Harikrishnan Mulackal','Kaan Uzdogan','Kamil Sliwak','Leonardo de Sa Alt','Mario Vega','Andrey Ashikhmin','Enrique Avila Asapche','Giulio Rebuffo','Michelangelo Riccobene','Tullio Canepa','Pooja Ranjan','Daniel Lehrner','Danno Ferrin','Gary Schulte','Jiri Peinlich','Justin Florentine','Karim Taam','Guru','Jim McDonald','Peter Davies','Adrian Manning','Diva Martínez','Mac Ladson','Mark Mackey','Mehdi Zerouali','Michael Sproul','Paul Hauner','Pawan Dhananjay Ravi','Sean Anderson','Cayman Nava','Dadepo Aderemi','dapplion','Gajinder Singh','Phil Ngo','Tuyen Nguyen','Daniel Caleda','Jorge Mederos','Łukasz Rozmej','Marcin Sobczak','Marek Moraczyński','Mateusz Jędrzejewski','Tanishq','Tomasz Stanzeck','James He','Kasey Kirkham','Nishant Das','potuz','Preston Van Loon','Radosław Kapka','Raul Jordan','Taran Singh','Terence Tsao','Sam Wilson','Dustin Brody','Etan Kissling','Eugene Kabanov','Jacek Sieka','Jordan Hrycaj','Kim De Mey','Konrad Staniec','Mamy Ratsimbazafy','Zahary Karadzhov','Adrian Sutton','Ben Edgington','Courtney Hunter','Dmitry Shmatko','Enrico Del Fante','Paul Harris','Alex Vlasov','Anton Nashatyrev','Mikhail Kalinin'];
  uint8[CORE_DEV_ARRAY_LEN] internal coreDevTeamIndices = [0,1,2,3,3,4,4,4,4,4,5,5,5,6,6,6,6,6,7,7,7,7,7,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,11,11,11,11,11,12,12,12,12,12,13,14,14,14,14,14,15,16,16,16,16,16,16,0,0,0,17,17,17,17,17,17,17,17,17,18,18,18,18,18,18,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,20,21,22,22,22,22,22,22,22,22,22,23,23,23,23,23,23,24,24,24];

  function getLinesPath() public pure returns (string memory) {
    return linesPath;
  }

  function getCoreDevArrayLen() public pure returns (uint8) {
    return CORE_DEV_ARRAY_LEN;
  }

  function getCoreDevName(uint8 idx) public view returns (string memory) {
    return coreDevNames[idx % CORE_DEV_ARRAY_LEN];
  }

  function getCoreDevTeamIndex(uint8 idx) public view returns (uint8) {
    return coreDevTeamIndices[idx % CORE_DEV_ARRAY_LEN];
  }

  function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = '0';
    buffer[1] = 'x';
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = ALPHABET[value & 0xf];
      value >>= 4;
    }
    return string(buffer);
  }

  function uint2str(uint _i) public pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }

  function int2str(int _i) public pure returns (string memory _uintAsString) {
    if (_i < 0) {
      return string(abi.encodePacked('-', uint2str(uint(0 - _i))));
    } else {
      return uint2str(uint(_i));
    }
  }

  // Get up to 8 bits from the 256-bit pseudorandom number gen (= generator[id])
  function getUint8(uint256 gen, uint8 startBit, uint8 bits) public pure returns (uint8) {
    uint8 gen8bits = uint8(gen >> startBit);
    if (bits >= 8) return gen8bits;
    return gen8bits % 2 ** bits;
  }

  function isMonochrome(uint256 gen) public pure returns (bool) {
    return getUint8(gen, 200, 4) == 0;
  }

  function getRGBA(uint256 gen, uint8 arraySection, string memory alpha) public view returns (string memory) {
    // Array section values are 0, 1, 2 or 3 (0 is darkest, 3 is lightest)
    // These sections give colours 0-7, 8-15, 16-23, 24-31
    uint8 bits = isMonochrome(gen) ? 1 : 3;
    uint8 idx = 8 * arraySection + getUint8(gen, sectionColStartBits[arraySection], bits); // First 2 out of 8 colours are monochrome, so 1 bit is monochrome, 3 bits is colour
    return string(abi.encodePacked(
      'rgba(',
      uint2str(colsR[idx]),
      ',',
      uint2str(colsG[idx]),
      ',',
      uint2str(colsB[idx]),
      ',',
      alpha,
      ')'
    ));
  }

  function getDurText(uint256 gen, uint8 arraySection) public view returns (string memory) {
    uint8 idx = 8 * arraySection + getUint8(gen, sectionColStartBits[arraySection] + 3, 3); // 3 bits = 8 duration choices
    return string(abi.encodePacked(
      ' dur="',
      uint2str(3 * durations[idx]), // It was rotating too fast! Extra factor here
      's"'
    ));
  }

  // Typical output: ' values="  0 200 200;  360 200 200;"' (with a lot more than 2 entries)
  // In this example output, prefix = ' ' and suffix = ' 200 200'
  // Note - this function only does whole-numbered interpolation
  function calcValues(int64 startVal, int64 endVal, string memory prefix, string memory suffix) public view returns (string memory) {
    string memory result = ' values="';
    for (uint8 idx = 0; idx < INTERP_LEN; idx++) {
      int64 a = int64(interpolationCurve10k[idx]);
      result = string(abi.encodePacked(
        result,
        prefix,
        int2str(((-a + 10000) * startVal + a * endVal) / 10000),
        suffix,
        idx == INTERP_LEN - 1 ? '"' : ';'
      ));      
    }
    return result;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import './SharedFnsAndData.sol';

// Mainnet 1

contract FractalStrings {

  SharedFnsAndData sfad;
  constructor(address sfadAddress) public {
    sfad = SharedFnsAndData(sfadAddress);
  }

  // To tesselate the Ethereum diamond, shapes are rectangles
  function defineShape(uint256 gen, uint8 sideIdx, uint8 colourIdxFill) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<rect id="shape',
      sfad.uint2str(sideIdx),
      '" x="-0.5" y="-0.5" width="1" height="1" rx="0.25" fill="',
      sfad.getRGBA(gen, colourIdxFill, "0.70"),
      '" stroke="',
      sfad.getRGBA(gen, 0, "0.80"),
      '" stroke-width="0.15px"/>'
    ));
  }

  function defineAllShapes(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      defineShape(gen, 0, 1),
      defineShape(gen, 1, 2)
    ));
  }

  uint16[8] internal xStarts = [250, 750, 250, 750, 250, 750, 250, 750];
  uint16[8] internal xEnds = [125, 375, 625, 875, 625, 875, 125, 375];
  function getIteration1Item(uint256 gen, uint8 sideIdx, uint8 itemIdx) private view returns (string memory) {
    uint8 idx = 4 * sideIdx + itemIdx;
    return string(abi.encodePacked(
      '<g transform="translate(-0.5, 0)"><animateTransform attributeName="transform" attributeType="XML" type="translate"',
      sfad.calcValues(xStarts[idx], xEnds[idx], '0.', itemIdx > 1 ? " -0.25" : " 0.25"),
      getAnimDurTxt(gen),
      ' repeatCount="indefinite" additive="sum"/><animateTransform attributeName="transform" attributeType="XML" type="scale"',
      sfad.calcValues(500, 250, '0.', ' 0.5'),
      getAnimDurTxt(gen),
      ' repeatCount="indefinite" additive="sum"/><use href="#shape',
      sfad.uint2str(sideIdx),
      '"/></g>'
    ));
  }

  // Defines it_1_0, it_1_1
  function defineIteration1(uint256 gen, uint8 sideIdx) internal view returns (string memory) {
    // sideIdx should be 0 (left) or 1 (right)
    return string(abi.encodePacked(
      '<g id="it_1_',
      sfad.uint2str(sideIdx),
      '">',
      getIteration1Item(gen, sideIdx, 0),
      getIteration1Item(gen, sideIdx, 1),
      getIteration1Item(gen, sideIdx, 2),
      getIteration1Item(gen, sideIdx, 3),
      '</g>'
    ));
  }

  // There are 4 potential dropouts, each has probability 2^(-DROPOUT_BITS)
  // Using DROPOUT_BITS = 2, so probability of 0, 1, 2, 3, 4 dropouts is 31%, 42%, 21%, 4.6%, 0.3%
  function countDropout01(uint256 gen, uint8 itemIdx) public view returns (uint8 result) {
    return sfad.getUint8(gen, 60 + 2 * itemIdx, 2) == 0 ? 1 : 0;
  }

  function countDropouts(uint256 gen) public view returns (uint8) {
    return countDropout01(gen, 0) + countDropout01(gen, 1) + countDropout01(gen, 2) + countDropout01(gen, 3);
  }

  function getDropoutAnimTxt(uint256 gen, uint8 itemIdx) internal view returns (string memory) {
    uint8 countDrop01 = countDropout01(gen, itemIdx);
    if (countDrop01 == 0) return '';
    return string(abi.encodePacked(
      '<animateTransform attributeName="transform" attributeType="XML" type="scale" values="1;1;0;0;0;0;1;1;1;1;1;1;1;1;1" dur="',
      sfad.uint2str(uint8(4 + itemIdx + 4 * sfad.getUint8(gen, 56 + itemIdx, 1))),  // Dropout cycle between 4 and 11 seconds, 1 bit random
      '.618s" repeatCount="indefinite" />'
    ));
  }

  // Probability 16 in 128 of rotation style, 8 in 128 of reflection, otherwise freestyle (104 in 128)
  function styleText(uint256 gen) public view returns (string memory) {
    if (countDropouts(gen) == 0) return 'Solid';
    uint8 style = styleNumber(gen);
    if (style < 16) return 'Spinner';
    if (style < 24) return 'Reflective';
    return 'Freestyle';
  }

  // If there are dropouts, 16 in 128 of rotation/spinner, 8 in 128 of reflective style
  function styleNumber(uint256 gen) internal view returns (uint8) {
    return sfad.getUint8(gen, 182, 7);  // free
  }

  // Returns 0 or 1. 0 scales by 0.5, 1 scales by -0.5
  uint8[4] internal xc = [0, 0, 1, 1];
  uint8[4] internal yc = [0, 1, 1, 0];
  function getReflectionNum(uint256 gen, uint8 itemIdx, uint8 coordIdx) internal view returns (uint8) {
    uint8 style = styleNumber(gen);
    if (style < 16) return 0;
    if (style < 24) {
      uint8 style2 = style - 16;
      uint8 x1 = style2 % 2;
      uint8 x2 = (style2 >> 1) % 2;
      uint8 y1 = (style2 >> 2) % 2;
      uint8 y2 = (style2 >> 3) % 2;
      if (coordIdx == 0) {
        return (x1 + x2 * xc[itemIdx]) % 2;
      } else {
        return (y1 + y2 * yc[itemIdx]) * 2;
      }
    }
    return sfad.getUint8(gen, 190 + coordIdx + 2 * itemIdx, 1);
  }

  // Returns 0, 1, 2, or 3
  // Multiply by 90 to get a rotation angle
  function getRotationNum(uint256 gen, uint8 itemIdx) internal view returns (uint8) {
    uint8 style = styleNumber(gen);
    if (style < 16) {
      uint8 r1 = style % 4; // 0..3
      uint8 r2 = style >> 2; // different 0..3
      return (r1 + r2 * itemIdx) % 4;
    }
    if (style < 24) return 0;
    return sfad.getUint8(gen, 48 + 2 * itemIdx, 2);
  }

  string[4] internal xs = ['-0.25','-0.25',' 0.25',' 0.25'];
  string[4] internal ys = ['-0.25',' 0.25',' 0.25','-0.25'];
  function getIterationNItem(uint256 gen, uint8 iteration, uint8 sideIdx, uint8 itemIdx) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<g>',
      iteration == RENDER_ITERATION ? '' : getDropoutAnimTxt(gen, itemIdx),
      '<use href="#it_',
      sfad.uint2str(iteration-1),
      '_',
      sfad.uint2str(sideIdx),
      '" transform="translate(',
      xs[itemIdx],
      ',',
      ys[itemIdx],
      ') rotate(',
      sfad.uint2str(90 * uint16(getRotationNum(gen, itemIdx))),
      ') scale(',
      getReflectionNum(gen, itemIdx, 0) == 1 ? '-0.5' : '0.5',
      ' ',
      getReflectionNum(gen, itemIdx, 1) == 1 ? '-0.5' : '0.5',
      ')"/></g>'
    ));
  }

  // side = 0, 1; iteration = 2, 3, 4; this uses 24 bits of randomness
  function getTwistIdx(uint256 gen, uint8 sideIdx, uint8 iteration) internal view returns (uint8) {
    return sfad.getUint8(gen, 76 + 4 * sideIdx + 8 * (iteration - 2), 4);
  }

  // Rotation at each level is at slightly different times to the overall movement
  uint8[16] internal twistCounts = [0,0,0,0,0 , 1,1,1,1,1,1,1,1,1,1,1];
  function getTwistiness(uint256 gen) public view returns (uint8) {
    return twistCounts[getTwistIdx(gen, 0, 2)]
    + twistCounts[getTwistIdx(gen, 1, 2)]
    + twistCounts[getTwistIdx(gen, 0, 3)]
    + twistCounts[getTwistIdx(gen, 1, 3)]
    + twistCounts[getTwistIdx(gen, 0, 4)]
    + twistCounts[getTwistIdx(gen, 1, 4)];
  }
  string[16] internal twistValues = [
    '0;0',
    '0;0',
    '0;0',
    '0;0',
    '0;0',
    '90;90;90;90;0;0;90',
    '-90;-90;-90;0;0;0;-90',
    '90;90;0;0;0;0;90',
    '90;90;60;30;0;0;90',
    '-90;-90;-90;-90;0;0;-45;-90',
    '-90;-90;0;0;0;0;0;-90',
    '90;90;45;0;0;0;0;90',
    '90;90;60;30;0;0;90;90',
    '-90;-90;-90;-90;-90;0;0;-90;-90',
    '90;90;90;90;0;0;0;44;90',
    '-90;-90;0;0;0;0;0;0;-90'
  ];
  // Defines `it_N_i` in terms of `it_[N-1]_i`
  function defineIterationN(uint256 gen, uint8 sideIdx, uint8 iteration) internal view returns (string memory) {
    // sideIdx should be 0 (left) or 1 (right)
    return string(abi.encodePacked(
      '<g id="it_',
      sfad.uint2str(iteration),
      '_',
      sfad.uint2str(sideIdx),
      '"><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="',
      twistValues[getTwistIdx(gen, sideIdx, iteration)],
      '" ',
      getAnimDurTxt(gen),
      ' repeatCount="indefinite" />',
      getIterationNItem(gen, iteration, sideIdx, 0),
      getIterationNItem(gen, iteration, sideIdx, 1),
      getIterationNItem(gen, iteration, sideIdx, 2),
      getIterationNItem(gen, iteration, sideIdx, 3),
      '</g>'
    ));
  }

  function renderEthereum(uint256 gen, uint8 sideIdx, uint8 iteration, int16 translate) public view returns (string memory) {
    return string(abi.encodePacked(
      '<g><animateTransform attributeName="transform" attributeType="XML" type="translate"',
      sfad.calcValues(0, 200 - translate, '', ''),
      getAnimDurTxt(gen),
      ' repeatCount="indefinite" additive="sum"/><use href="#it_',
      sfad.uint2str(iteration),
      '_',
      sfad.uint2str(sideIdx),
      '" transform="translate(',
      sfad.int2str(translate),
      ', 200) scale(95, 190) rotate(45)"/></g>'
    ));
  }

  // Animation time between 3 and 39 seconds, mostly in the middle of the range
  // Uses 8 bits of randomness
  function getAnimDurS(uint256 gen) public view returns (uint8) {
    uint8 r255 = sfad.getUint8(gen, 16, 8); // 0 to 255
    uint8 r15 = r255 % 4 + (r255 >> 2) % 4 + (r255 >> 4) % 4 + (r255 >> 6) % 4; // Between 0 and 12
    return 3 * (1 + r15);
  }

  // Format of output is ' dur="5s"'
  function getAnimDurTxt(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      ' dur="',
      sfad.uint2str(getAnimDurS(gen)),
      's"'
    ));
  }

  uint8 internal constant RENDER_ITERATION = 4;
  function renderEthereums(uint256 gen) public view returns (string memory) {
    return string(abi.encodePacked(
      '<defs>',
      defineAllShapes(gen),
      defineIteration1(gen, 0),
      defineIteration1(gen, 1),
      defineIterationN(gen, 0, 2),
      defineIterationN(gen, 1, 2),
      defineIterationN(gen, 0, 3),
      defineIterationN(gen, 1, 3),
      defineIterationN(gen, 0, 4),
      defineIterationN(gen, 1, 4), // up to iteration 4 can be rendered
      '</defs>',
      renderEthereum(gen, 0, RENDER_ITERATION, 125),
      renderEthereum(gen, 1, RENDER_ITERATION, 275)
    ));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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