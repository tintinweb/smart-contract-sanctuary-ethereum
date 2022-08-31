// SPDX-License-Identifier: MIT
// Stacks721(tm) / StacksNET(tm) : Stacks and Stacks of Multimedia
// CryptoComics.com - A media token library marketplace built for blockchain networks.
// (c) Copyright 2022, j0zf at apogeeinvent.com
// Stacks721.sol : 20220514 Stacks721(tm) NonFungible Series Tokens by j0zf at apogeeinvent.com - version 1.2.1
// Stacks721.sol : CryptoStacks(tm) Stacks721 by j0zf at ApogeeINVENT(tm) 2021-02-28
// .   .       .:      ...   .     * .         ..   :    .        .       .  + .     .  .  +
//   .   . x      . -      . ..       .  ...   .       .    + .          .    .    *        
//      .        .   .   .        ---=*{[ CryptoComics.com ]}*=--    .  x   .   .       .. 
//  .     .  .   . .   *   . .    +  .   .      .   .  .      :.       .              .    .
//    .  .   . .       . .       .   .      .   .  .       .       .      .     ..    .    .
//  .  :     .    ..        ____  __ __      .   *  .   :       ;  .     -=-              . 
// .        .    .   . ."_".^ .^ ^. "'.^`:`-_  .    .    .    .      .       .    :.     .  
//  .   .    +.    ,:".   .    .    "   . . .:`    .  +  .  *    .   .   . ..  .        .   
//   .     . _   ./:           `   .  ^ .  . .:``   _ .       :.     .   .  .       .       
// .   . -      ./.                   .    .  .:`\      . -      .    .  .   .    .     o  :
//   .     .   .':                       .   . .:!.   .        -+-     + + . . ..  .       :
//   O  .      .!                            . !::.      .   .         .   . .:  .     .   +
//  . . .  :.  :!    ^                    ^  . ::!:  .   .      .   :     .   .         .   
//     - .     .:.  .o..               ...o.   ::|. .   : .  .   :  .  .  .   .    .  x     
//   :     .   `: .ooooooo.          .ooooooo :::.   :.   :  _____________                :.
// .  ..  .  .. `! .ooOooooo        .ooooOooo .:'  ..  .   /   .   .       :\ .  . - .   .  
//     .+    : -. \ .ooO*Ooo.      .ooO*Oooo .:'  -     ./   ____________ ,::\ :  .  . .  . 
// .+   .   . .  . \. .oooOoo      :oOooooo..:' .  . . .!| / .   .      `::\::!" .    .  ,  
// : .     .     .. .\ .ooooo      :ooooo.::'   . .   . ( '  .  .         ::!:.)    .  .    
// .   .  .. :  -    .\    ..   .   .. ::.:' . .    : . | !   . .        .::|:|)    -      .
//   +     .  .- ." .  .\      ||     ..:'. .  .  -.  .  . .    .        ::/ //.  .    +    
//  -.   . ` . .  .   . .\.    ``     .:' .  . :. . . .  _\ \___________.:` //___    . - .  
//  .  :        .  .  _ ..:\  .___/  :'. .: _ . .  .    /  \.__ :  : _. ___/ ::""\\     .   
// .  .   . . .. .  .:  . .:\       :': . .    . .  .  !     ''..:.:::/`      `:::||       .
//   .   .     .   .  . . .:.`\_(__/ ::. . :.: .  :.   |     ! :  !  .===   ..  ::||.   x + 
//\___________-...:::::::::::!|    .:\;::::::::::::::::|:   .!  + !!  BOB :.``   :.|::..-___
//            \\:::::::::::../.  ^.: :.;:::::::::::::::!   :!`.  .!.   ^   :::   :!:::://   
//             \\::::::.::::/  .  .:: ::\:::::::::::::.:. .:|`    !! .| |  ::: . :.!:://    
//              \\:_________________________________________________________________://     

pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";

contract Stacks721 is ERC721 {
	using SafeMath for uint256;
	uint32 private _Role_Boss_;
	uint32 private _Role_Mgmt_;
	uint32 private _Role_Bank_;
	uint32 private _Role_Mark_;
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

	uint256 private _tokensIssued = 0;
    mapping(uint32 => mapping(address => bool)) private _roles;
	string[] private _roleNames;
	mapping(string => string) private _values;
	mapping(string => uint256) private _numbers;
	uint256 private _deposits;
	uint256 private _withdrawals;

	struct Series {
		string symbol; // Symbol of a classification "series item" to be tokenized (ie. comic issue)
		address payee; // Royalties / Payment Splitters (for external markets)
		uint256 percent; // Overrides the contract default royalty percentage
		uint256 limit; // Max number of tokens to issue per series item
		uint256 issued; // Total number of tokens issued for series item
	}

	struct TokenData {
		uint256 seriesId; // the Series Item classification this token belongs to
		uint256 number; // serial number issued for this series item
	}

	Series[] private _series; // indexed by seriesId
	mapping(uint256 => TokenData) private _tokenData; // indexed by tokenId
	mapping(string => uint256) private _symbol2series; // symbol => seriesId
	mapping(uint256 => uint256[]) private _series2tokens; // [seriesId][number - 1] => tokenId

	constructor(string memory name, string memory symbol, string memory baseURI, string memory contractURI) public ERC721(name, symbol) {
		_values["name"] = name;
		_values["symbol"] = symbol;
		_values["baseURI"] = baseURI;
		_values["contractURI"] = contractURI;
		_values["version"] = "1.2.1";
		_numbers["paused"] = 0;
		_numbers["royalty_percent"] = 20;
		_Role_Boss_ = _setupRole("BOSS", msg.sender);
		_Role_Mgmt_ = _setupRole("MGMT", msg.sender);
		_Role_Bank_ = _setupRole("BANK", msg.sender);
		_Role_Mark_ = _setupRole("MARK", msg.sender);
		_registerInterface(_INTERFACE_ID_ERC2981);
		_setBaseURI(baseURI);
		_series.push(Series({ symbol: "", payee: address(0), percent: 0, limit: 0, issued: 0 })); // nullify index 0
	}

	receive () external payable {
		_deposits = _deposits.add(msg.value);
		emit DepositReceived(msg.sender, msg.value, _deposits, address(this).balance);
	}
	event DepositReceived(address indexed from, uint256 amount, uint256 deposits, uint256 balance);

	function withdraw(address payable to, uint256 amount) external {
		require(hasRole(_Role_Bank_, msg.sender), "DENIED");
		_withdrawals = _withdrawals.add(amount);
		to.transfer(amount);
		emit Withdrawn(to, amount, _withdrawals, address(this).balance);
	}
	event Withdrawn(address indexed to, uint256 amount, uint256 withdrawals, uint256 balance);

	////////////////////////////////////////////////////////////////////////////////

	function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
		// EIP-2981: NFT Royalty Standard https://eips.ethereum.org/EIPS/eip-2981
		if (!_exists(tokenId)) return (address(this), 0);
		Series memory seriesItem = _series[_tokenData[tokenId].seriesId];
		uint256 royaltyPercent = ( seriesItem.percent > 0 ? seriesItem.percent : _numbers["royalty_percent"] );
		uint256 royaltyAmount_ = _percentOf(royaltyPercent, salePrice);
		address receiver_ = ( seriesItem.payee != address(0) ? seriesItem.payee : address(this) );
		return (receiver_, royaltyAmount_);
	}

	function contractURI() public view returns (string memory) {
		// ref: https://docs.opensea.io/docs/contract-level-metadata
		return _values["contractURI"];
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "NONEXISTENT");
		string memory base = baseURI();
		TokenData memory tokenData = _tokenData[tokenId];
		Series memory seriesItem = _series[tokenData.seriesId];
		return string(abi.encodePacked(base, "/", seriesItem.symbol, "/", tokenData.number.toString(), "/", tokenId.toString()));
	}

	function mint(uint256 seriesId, address to) external {
		require(hasRole(_Role_Mgmt_, msg.sender), "DENIED");
		Series memory seriesItem = _series[seriesId];
		require(_symbolSanity(seriesItem.symbol), "INVALID"); 
		require(seriesItem.issued < seriesItem.limit, "LIMITED");
		uint256 tokenId = _tokensIssued + 1; // tokenId => 1 will be the first tokenId, reserving a tokenId of 0 as a null token.
		_tokensIssued = _tokensIssued.add(1);
		seriesItem.issued = seriesItem.issued.add(1);
		_series[seriesId] = seriesItem;
		TokenData memory tokenData = TokenData({ seriesId: seriesId, number: seriesItem.issued });
		_tokenData[tokenId] = tokenData;
		_series2tokens[tokenData.seriesId].push(tokenId);
		_mint(to, tokenId);
	}

	function isApprovedForAll(address owner, address operator) public override view returns (bool isOperator) {
		// Market Managed Token _Role_Mark_ (ref CryptoComics.com / StacksNET.io)
		// also recommended by OpenSea (OpenSea's ERC721 Proxy Address 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)
		// ref: https://docs.opensea.io/docs/polygon-basic-integration
		if (hasRole(_Role_Mark_, operator)) return true;
        return ERC721.isApprovedForAll(owner, operator);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "INVALID");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "DENIED");
        _approve(to, tokenId);
    }

	////////////////////////////////////////////////////////////////////////////////

	function setSeries(uint256 seriesId, string calldata symbol, address payee, uint256 percent, uint256 limit) external {
		// Tokens are classified in series represented by their "Series". (ie. symbol => seriesId => Series seriesItem)
		// @param seriesId 0 publishes a new Series Item
		// @param symbol A-Za-z0-9 (allows '-' and '_' but not on ends). 
		//	- symbols may be _changed_, but previous symbols remain alias to the same series item, and cannot be used by other Series.
		// @param payee for external markets royaltyInfo, payment splitters, publishers, etc.
		// @param percent this overrides the contracts default royalty_percent in royaltyInfo() (0: defaults to contract)
		// @param limit for new series > 0, limit may be lowered as much as the number issued
		require(hasRole(_Role_Mgmt_, msg.sender), "DENIED");
		require(_symbolSanity(symbol), "SYMBOL");
		require(seriesId < _series.length, "INVALID");
		Series memory seriesItem = _series[seriesId];
		// RULE a.) New Series with a limit, or b.) Limit may be reduced as low as the number issued thus far.
		require( (seriesId == 0 && limit > 0) || (seriesItem.issued <= limit && limit <= seriesItem.limit), "LIMITED");
		bool symbolChanged = ( keccak256(bytes(seriesItem.symbol)) != keccak256(bytes(symbol)) );
		// RULE a.) the symbol doesn't exist, or b.) the symbol exists and has the same seriesId, or c.) the symbol isn't changing
		require( _symbol2series[symbol] == 0 ||  _symbol2series[symbol] == seriesId || !symbolChanged, "TAKEN");

		seriesItem.symbol = symbol;
		seriesItem.payee = payee;
		seriesItem.percent = percent;
		seriesItem.limit = limit;

		if (seriesId == 0) { // new seriesItem
			seriesId = _series.length;
			_series.push(seriesItem);
		} else { // update seriesItem
			_series[seriesId] = seriesItem;
		}

		_symbol2series[symbol] = seriesId; // previous symbol remains (reliable alias)
		emit SeriesSet(seriesId, symbol, payee, percent, limit, symbolChanged);
	}
	event SeriesSet(uint256 indexed seriesId, string indexed symbol, address payee, uint256 percent, uint256 limit, bool symbolChanged);

	function getSeriesId(string calldata symbol) external view returns (uint256) {
		return _symbol2series[symbol];
	}

	function getSeries(uint256 seriesId) external view returns ( 
		string memory symbol, address payee, uint256 percent, uint256 limit, uint256 issued, string memory seriesURI
	) {
		Series memory seriesItem = _series[seriesId];
		string memory seriesURI_ = string(abi.encodePacked(baseURI(), "/", seriesItem.symbol, "/0/0"));
		return ( seriesItem.symbol, seriesItem.payee, seriesItem.percent, seriesItem.limit, seriesItem.issued, seriesURI_ );
	}

	function getTokenSeries(uint256 tokenId) external view returns ( 
		string memory symbol, address payee, uint256 percent, uint256 limit, uint256 issued 
	) {
		Series memory seriesItem = _series[_tokenData[tokenId].seriesId];
		return ( seriesItem.symbol, seriesItem.payee, seriesItem.percent, seriesItem.limit, seriesItem.issued );
	}
	
	function getSeriesToken(uint256 seriesId, uint256 number) external view returns (uint256) {
		// @returns tokenId of Series/Number
		if (number > 0 && number <= _series2tokens[seriesId].length) {
			return _series2tokens[seriesId][number - 1];
		}
		return 0;
	}

	function getSeriesCount() external view returns (uint256) {
		// _series is numbered 1-N, with the 0 position reserved for the "NULL" (init in constructor)
		return _series.length - 1;
	}

	function getTokenData(uint256 tokenId) external view 
	returns (address owner, uint256 seriesId, uint256 number) {
		TokenData memory tokenData = _tokenData[tokenId];
		return (ERC721.ownerOf(tokenId), tokenData.seriesId, tokenData.number);
	}

	////////////////////////////////////////////////////////////////////////////////

	function _setupRole(string memory roleName, address account) internal returns (uint32) {
		if (_roleNames.length < 1) {
			_roleNames.push(""); // using index 0 as eq to null
		}
		for (uint32 i; i < _roleNames.length; i++) {
			require(keccak256(bytes(roleName)) != keccak256(bytes(_roleNames[i])), "TAKEN");
		}
		_roleNames.push(roleName);
		uint32 role = uint32 (_roleNames.length.sub(1));
		_roles[role][account] = true;
		emit RoleSetup(role, account, roleName);
		return role;
	}
	event RoleSetup(uint32 indexed role, address indexed account, string roleName);

	function setRole(uint32 role, address account, bool enroll) public {
		require(hasRole(_Role_Boss_, msg.sender), "DENIED");
		_roles[role][account] = enroll;
		emit RoleSet(role, account, enroll);
	}
	event RoleSet(uint32 role, address account, bool enroll);

	function hasRole(uint32 role, address account) public view returns (bool) {
		return _roles[role][account];
	}

	function getRoleName(uint32 role) external view returns (string memory) {
		return role < _roleNames.length ? _roleNames[role] : _roleNames[0];
	}

	function setValue(string calldata n, string calldata v) external {
		require(hasRole(_Role_Mgmt_, msg.sender), "DENIED");
		if (keccak256(bytes(n)) == keccak256(bytes("baseURI"))) {
			_setBaseURI(v); // this also needs to be set internally for the parent class
		}
		_values[n] = v;
		emit ValuesSet(n, v);
	}
	event ValuesSet(string indexed n, string  v);

	function getValue(string calldata n) external view returns (string memory) {
		return _values[n];
	}

	function setNumber(string calldata n, uint256 v) external {
		require(hasRole(_Role_Mgmt_, msg.sender), "DENIED");
		_numbers[n] = v;
		emit NumbersSet(n, v);
	}
	event NumbersSet(string indexed n, uint256  v);

	function getNumber(string calldata n) external view returns (uint256) {
		return _numbers[n];
	}

	////////////////////////////////////////////////////////////////////////////////

	function name() public view virtual override returns (string memory) {
		return _values["name"];
	}

	function symbol() override public view virtual returns (string memory) {
		return _values["symbol"];
	}

	////////////////////////////////////////////////////////////////////////////////

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
		require(hasRole(_Role_Mgmt_, msg.sender) || _numbers["paused"] == 0, "PAUSED");
    }

	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        require(_exists(tokenId), "NONEXISTENT");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

	function _symbolSanity(string memory str) internal pure returns (bool) {
		// Symbol sanity check
		bytes memory b = bytes (str);
		uint8 c = 0;
		uint8 e = 0;
		if (b.length < 1) return false;
		for (uint i = 0; i < b.length; i++) {
			c = uint8 (b[i]);
			if ( !( 
				// LIST OF ALLOWED CHARS
				c == 45 // '-'
				|| ( c >= 48 && c <= 57 ) // 0 to 9
				|| ( c >= 65 && c <= 90 ) // A to Z
				|| c == 95 // '_'
				|| ( c >= 97 && c <= 122 ) // a to z
			) ) {
				return false;
			}
		}
		c = uint8 (b[0]);
		e = uint8 (b[b.length - 1]);
		if ( c == 45 || e == 45   // no '-' on ends
			|| c == 95 || e == 95 // no '_' on ends
		) {
			return false;
		}
		return true;
	}

	function _percentOf(uint256 percent, uint256 x) internal pure returns (uint256) {
		// get truncated percentage of x, discards remainder. (percent is a whole number percent)
		return x.mul(percent).div(100);
	}
}