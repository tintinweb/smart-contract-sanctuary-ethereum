// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Digil Token (NFT)
/// @author gSOLO
/// @notice NFT contract used for the creation, charging, and activation of Digital Sigils on the Ethereum Blockchain
/// @custom:security-contact [email protected]
contract DigilToken is ERC721, Ownable, IERC721Receiver {
    using Strings for uint256;
    
    IERC20 private _coins = IERC20(0xa4101FEDAd52A85FeE0C85BcFcAB972fb7Cc7c0e);
    uint256 private _coinDecimals = 10 ** 18;
    uint256 private _coinRate = 100 * 10 ** 18;

    uint256 private _incrementalValue = 100 * 1000 gwei;
    uint256 private _transferValue = 95 * 1000 gwei;

    bool _paused;
    address _this;

    mapping(uint256 => Token) private _tokens;
    mapping(address => bool) private _blacklisted;
    mapping(address => Distribution) private _distributions;
    mapping(address => mapping(uint256 => bool)) private _contractTokenExists;
    mapping(address => mapping(uint256 => ContractToken)) private _contractTokens;

    /// @dev Pending Coin and Value Distributions, and the Time of the last Distribution
    struct Distribution {
        uint256 time;
        uint256 coins;
        uint256 value;
    }

    /// @dev Information about how much was Contributed to a Token's Charge
    struct TokenContribution {
        uint256 charge;
        uint256 value;
        bool exists;
        bool distributed;
        bool whitelisted;
    }

    /// @dev Illustrates the relationship between an external ERC721 token and a Digil Token
    struct ContractToken {
        uint256 tokenId;
        bool recallable;
    }

    struct LinkEfficiency {
        uint8 base;
        uint256 affinityBonus;
    }

    /// @dev Token information
    struct Token {
        uint256 charge;
        uint256 activeCharge;
        uint256 value;
        uint256 incrementalValue;
        
        uint256[] links;
        mapping(uint256 => LinkEfficiency) linkEfficiency;

        address[] contributors;
        mapping(address => TokenContribution) contributions;

        bool active;
        uint256 activationThreshold;
        
        bytes data;
        string uri;

        bool restricted;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /// @dev Configuration was updated
    event Configure(uint256 coinRate, uint256 incrementalValue, uint256 transferValue);

    /// @dev Contract was Paused
    event Pause();

    /// @dev Contract was Unpaused
    event Unpause();

    /// @dev Address was added to the contract Blacklist
    event Blacklist(address indexed account);

    /// @dev Address was removed from the contract Blacklist
    event Whitelist(address indexed account);

    /// @dev Address was added to a Token's Whitelist
    event Whitelist(address indexed account, uint256 indexed tokenId);

    /// @notice Token was Created
    event Create(uint256 indexed tokenId);

    /// @notice Token was Restricted
    event Restrict(uint256 indexed tokenId);

    /// @notice Token was Updated
    event Update(uint256 indexed tokenId);

    /// @notice Token was Activated
    event Activate(uint256 indexed tokenId);

    /// @notice Token was Charged
    event Charge(address indexed addr, uint256 indexed tokenId, uint256 coins);

    /// @notice Active Token was Charged
    event ActiveCharge(uint256 indexed tokenId, uint256 coins);

    /// @notice Token was Discharged
    event Discharge(uint256 indexed tokenId);

    /// @notice Token was Destroyed
    event Destroy(uint256 indexed tokenId);

    /// @notice Token was Linked to a Plane
    event Link(uint256 indexed tokenId, uint256 indexed linkId);

    /// @notice Token was Linked
    event Link(uint256 indexed tokenId, uint256 indexed linkId, uint8 efficiency, uint256 affinityBonus);

    /// @notice Token was Unlinked
    event Unlink(uint256 indexed tokenId, uint256 indexed linkId);

    /// @notice Value was generated for the Contract
    event ContractDistribution(uint256 value);

    /// @notice Coins and Value was generated for a given address
    event PendingDistribution(address indexed addr, uint256 coins, uint256 value);

    /// @notice Charged Value was Contributed to a Token
    event Contribute(address indexed addr, uint256 indexed tokenId, uint256 value);

    /// @notice Value was Contributed directly to a Token
    event ContributeValue(address indexed addr, uint256 indexed tokenId, uint256 value);

    /// @notice Value was Added to a Token
    event ContributeValue(uint256 indexed tokenId, uint256 value);

    constructor() ERC721("Digil Token", "DiGiL") {
        _this = address(this);
        _coins.approve(_this, type(uint256).max);
        
        address sender = msg.sender;
        string memory baseURI = "https://digil.co.in/token/";
        
        string[21] memory plane;
        plane[0] =  "";
        plane[1] =  "void";
        plane[2] =  "karma";
        plane[3] =  "kaos";
        plane[4] =  "fire";
        plane[5] =  "air";
        plane[6] =  "earth";
        plane[7] =  "water";
        plane[8] =  "ice";
        plane[9] =  "lightning";
        plane[10] = "metal";
        plane[11] = "nature";
        plane[12] = "harmony";
        plane[13] = "discord";
        plane[14] = "entropy";
        plane[15] = "exergy";
        plane[16] = "magick";
        plane[17] = "aether";
        plane[18] = "world";
        plane[19] = "virtual";
        plane[20] = "ilxr";

        bytes[21] memory data;
        data[0] =  "----|";      // null
        data[1] =  "xrot|X";     // void
        data[2] =  "roxw|K.N ";  // karma
        data[3] =  "orxw|K.S";   // kaos
        data[4] =  "falw|X.S";   // fire
        data[5] =  "aflw|X.E";   // air
        data[6] =  "ewnw|X.N";   // earth
        data[7] =  "wenw|X.W";   // water
        data[8] =  "im-w|X.NW";  // ice
        data[9] =  "lfaw|X.NE";  // lightning
        data[10] = "mi-w|X.NNE"; // metal
        data[11] = "neww|X.NNW"; // nature
        data[12] = "hrdw|X.SE";  // harmony
        data[13] = "dohw|X.SW";  // discord
        data[14] = "podt|K.W";   // entropy
        data[15] = "grht|K.E";   // negentropy/exergy
        data[16] = "kpgt|K";     // magick/kosmos
        data[17] = "txw-|K.X";   // aether
        data[18] = "wxt-|X.R";   // external reality
        data[19] = "----|.XR";   // extended reality
        data[20] = "----|.ILXR"; // digil reality
        
        unchecked {
            uint256 tokenId;
            while (tokenId < 20) {
                tokenId = _tokenIdCounter.current();
                _tokenIdCounter.increment();

                _mint(sender, tokenId);

                Token storage t = _tokens[tokenId];
                t.active = true;
                t.uri = string(abi.encodePacked(baseURI, plane[tokenId]));
                t.data = data[tokenId];
            }
        }

        _tokens[0].restricted = true;
        _tokens[20].restricted = true;
    }

    function _ownerIsSender() private view returns(bool) {
        return owner() == _msgSender();
    }

    function _onlyOwner() private view {
        require(_ownerIsSender(), "DiGiL: Caller Is Not Owner");
    }

    modifier admin() {
        _onlyOwner();
        _;
    }

    /// @dev    Update contract configuration.
    /// @param  coins Used to determine a number of values:
    ///                     Maximum number of bonus Coins a user can withdraw.
    ///                     Number of Coins required to Update a Token URI.
    ///                     Number of Coins required to Link a Token.
    ///                     Number of Coins required to Opt-Out.
    /// @param  value The minimum value (in twei) used to Charge, Activate a Token, update a Token URI
    /// @param  valueTransferred The value (in twei) to be distributed when a Token is Activated as a percentage of the minimum value
    function configure(uint256 coins, uint256 value, uint256 valueTransferred) public admin {
        require(coins > 0 && valueTransferred <= value && valueTransferred >= (value / 2), "DiGiL: Invalid Configuration");

        _coins.approve(_this, type(uint256).max);
        _coinRate = coins * _coinDecimals;

        _incrementalValue = value * 1000 gwei;
        _transferValue = valueTransferred * 1000 gwei;
        
        emit Configure(_coinRate, _incrementalValue, _transferValue);
    }

    // Coin Transfers
    function _coinsFromSender(uint256 coins) internal {
        require(_transferCoinsFrom(_msgSender(), _this, coins), "DiGiL: Coin Transfer Failed");
    }

    function _transferCoinsFrom(address from, address to, uint256 coins) internal returns(bool success) {
        try _coins.transferFrom(from, to, coins) returns (bool _success) {
            success = _success;
        } catch { }
    } 

    /// @notice Accepts all payments.
    /// @dev    The origin of the payment is not tracked by the contract, but the accumulated balance can be used by the admin to add Value to Tokens.
    receive() external payable {
        _addValue(msg.value);
    }

    /// @notice Will transfer any pending Coin and Value Distributions associated with the sender.
    ///         A number of bonus Coins are available every 15 minutes for those who already hold Coins, Tokens, or have any pending Value distributions.
    /// @return coins The number of Coins transferred
    /// @return value The Value transferred
    function withdraw() public enabled returns(uint256 coins, uint256 value) {
        address addr = _msgSender();
        _notOnBlacklist(addr);

        Distribution storage distribution = _distributions[addr];

        value = distribution.value;
        distribution.value = 0;

        coins = distribution.coins;
        distribution.coins = 0;

        if (value > 0 || balanceOf(addr) > 0 || _coins.balanceOf(addr) > 0) {
            uint256 lastBonusTime = distribution.time;            
            distribution.time = block.timestamp;
            uint256 bonus = (block.timestamp - lastBonusTime) / 15 minutes * _coinDecimals;
            coins += (bonus < _coinRate ? bonus : _coinRate);
        }

        if (value > 0) {            
            Address.sendValue(payable(addr), value);
        }

        if (coins > 0 && !_transferCoinsFrom(_this, addr, coins)) {
            distribution.coins = coins;
            coins = 0;
        }

        return (coins, value);
    }

    function _addValue(uint256 value) private {
        if (value > 0) {
            _addValue(_this, value, 0);
            emit ContractDistribution(value);
        }
    }

    function _addValue(address addr, uint256 value, uint256 coins) private {
        if (value > 0 || coins > 0) {
            Distribution storage distribution = _distributions[addr];
            distribution.value += value;
            distribution.coins += coins;
            if (addr != _this) {
                emit PendingDistribution(addr, coins, value);
            }
        }
    }

    /// @dev    Adds a percentage of the value to be Distributed to the contract, and the rest to the address specified.
    ///         Adds all the Coins to be Distributed to the address specified along with an additional number of bonus coins based on the value to be Distributed.
    ///         An example 1 eth, 100 Coin distribution with a chargeRate of 100 and a transferRate of 95 would:
    ///             Add 0.05 eth to the contract.
    ///             Add 0.95 eth to the address specified.
    ///             Add 1100 Coins to the address specified (1000 bonus Coins)
    function _addDistribution(address addr, uint256 value, uint256 coins) internal {
        uint256 incrementalDistribution = value / _incrementalValue;
        _addValue(incrementalDistribution * (_incrementalValue - _transferValue));
        uint256 bonusCoins = _coinRate / 1000 * incrementalDistribution;
        _addValue(addr, incrementalDistribution * _transferValue, coins + bonusCoins);
    }

    function _createValue(uint256 tokenId, uint256 value) internal {
        _tokens[tokenId].value += value;
        emit ContributeValue(tokenId, value);
    }

    /// @dev    Adds Value to the specified Token using the contract's available balance.
    /// @param  tokenId The ID of the Token to add Value to
    /// @param  value The Value to add to the Token
    function createValue(uint256 tokenId, uint256 value) public payable admin {
        _addValue(msg.value);

        _distributions[_this].value -= value;

        _createValue(tokenId, value);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal enabled override
    {
        super._beforeTokenTransfer(from, to, tokenId);
        _notOnBlacklist(from);
        _notOnBlacklist(to);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal enabled override
    {
        super._afterTokenTransfer(from, to, tokenId);
        _tokens[tokenId].contributions[to].whitelisted = true;
    }

    function _whenNotPaused() private view {
        require(_paused == false, "DiGiL: Paused");
    }

    function _enabled(address account) private view {
        _whenNotPaused();
        _notOnBlacklist(account);
    }

    modifier approved(uint256 tokenId) {
        address account = _msgSender();
        _enabled(account);
        require(_isApprovedOrOwner(account, tokenId), "DiGiL: Not Approved");
        _;
    }

    modifier operatorEnabled(address account) {
        _enabled(account);
        _;
    }

    modifier enabled() {
        _whenNotPaused();
        _;
    }

    /// @dev Pause the contract
    function pause() public admin {
        _paused = true;
        emit Pause();
    }

    /// @dev Unpause the contract
    function unpause() public admin {
        _paused = false;
        emit Unpause();
    }

    // Blacklist
    function _notOnBlacklist(address account) internal view {
        require(!_blacklisted[account], "DiGiL: Blacklisted");
    }

    function _blacklist(address account) private {
        _notOnBlacklist(account);
        _blacklisted[account] = true;
        emit Blacklist(account);
    }

    /// @dev    Add account to Blacklist
    /// @param  account The address to Blacklist
    function blacklist(address account) public admin {
        require(account != address(0) && account != owner(), "DiGiL: Invalid Blacklist Address");
        _blacklist(account);
    }

    /// @notice Opt-Out to prevent Token transfers to/from sender.
    ///         Requires Incremental Value at the current Coin Rate.
    function optOut() public payable {
        require(msg.value >= _incrementalValue * _coinRate / _coinDecimals, "DiGiL: Insufficient Funds");
        _blacklist(_msgSender());
        _addValue(msg.value);
    }

    /// @dev    Remove account from Blacklist.
    /// @param  account The address to Whitelist
    function whitelist(address account) public admin {
        require(_blacklisted[account], "DiGiL: Whitelisted");
        _blacklisted[account] = false;
        emit Whitelist(account);
    }

    /// @dev    When an ERC721 token is sent to this contract, creates a new Token representing the token received.
    ///         The Incremental Value of the Token is set to the Minimum Non-Zero Incremental Value, with an Activation Threshold of 0.
    ///         The account (ERC721 contract address), and external token ID are appended to the Token URI as a query string.
    ///         Any data sent is stored with the Token and forwarded during Safe Transfer when {recallToken} is called.
    ///         If the ERC721 received is a DigilToken it is linked to the new Token.
    /// @param  operator The address which called safeTransferFrom on the ERC721 token contract
    /// @param  from The previous owner of the ERC721 token
    /// @param  tokenId The ID of the ERC721 token
    /// @param  data Optional data sent from the ERC721 token contract
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external operatorEnabled(operator) returns (bytes4) {
        address account = _msgSender();     
        require(!_contractTokenExists[account][tokenId], "DiGiL: Contract Token Already Exists");
        _contractTokenExists[account][tokenId] = true;

        uint256 internalId = _createToken(from, 0, 0, data);        
        _contractTokens[account][internalId].tokenId = tokenId;

        Token storage t = _tokens[internalId];
        t.uri = string(abi.encodePacked(tokenURI(internalId), "?account=", Strings.toHexString(uint160(account), 20), "&tokenId=", tokenId.toString()));
        t.contributors.push(account);

        uint256 minimumIncrementalValue = _incrementalValue;
        if (account == _this) {
            Token storage d = _tokens[tokenId];
            d.links.push(internalId);
            d.linkEfficiency[internalId] = LinkEfficiency(uint8(100 / d.links.length), 0);
            uint256 dIncrementalValue = d.incrementalValue;
            if (minimumIncrementalValue < dIncrementalValue) {
                minimumIncrementalValue = dIncrementalValue;
            }
        }
        t.incrementalValue = minimumIncrementalValue;
        
        return this.onERC721Received.selector;
    }

    /// @notice Return the Contract Token to the current owner. The Token the Contract Token is attached to must have been Activated or Destroyed.
    ///         Requires a Value sent greater than or equal to the Token's Incremental Value.
    function recallToken(address account, uint256 tokenId) public approved(tokenId) {
        ContractToken storage contractToken = _contractTokens[account][tokenId];
        require(contractToken.recallable, "DiGiL: Contract Token Is Not Recallable");

        uint256 contractTokenId = contractToken.tokenId;
        contractToken.tokenId = 0;
        contractToken.recallable = false;

        ERC721(account).safeTransferFrom(_this, ownerOf(tokenId), contractTokenId, _tokens[tokenId].data);

        _contractTokenExists[account][contractTokenId] = false;
    }

    // Token Information
    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId), "DiGiL: Token Does Not Exist");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokens[0].uri;
    }

    /// @notice Get the URI of a Token
    /// @dev    If the URI of the Token is explicitly set, it will be returned. 
    ///         If the URI of the Token is not set, a concatenation of the base URI and the Token ID is returned (the default behavior).
    /// @param  tokenId The ID of the Token to retrieve the URI for
    /// @return The Token URI if the Token exists. 
    function tokenURI(uint256 tokenId) public view virtual override tokenExists(tokenId) returns (string memory) {
        string storage uri = _tokens[tokenId].uri;

        if (bytes(uri).length > 0) {
            return string(abi.encodePacked(uri));
        }

        return super.tokenURI(tokenId);
    }

    /// @notice Get the Charge and Value of a Token
    /// @dev    The Value and Charged Value can be added together to give the Token's Total Value.
    ///         The Charged Value is derived from the Token's Charge and Incremental Value (Charge (decimals excluded) * Incremental Value)
    /// @param  tokenId The ID of the token whose Data is to be returned
    /// @return charge The current Charge of the Token
    /// @return activeCharge The current Charge of the Token generated from Links
    /// @return value The current Value the Token
    /// @return incrementalValue The Incremental Value of the Token
    /// @return activationThreshold The Activation Threshold of the Token
    function tokenCharge(uint256 tokenId) public view tokenExists(tokenId) returns(uint256 charge, uint256 activeCharge, uint256 value, uint256 incrementalValue, uint256 activationThreshold) {
        Token storage t = _tokens[tokenId]; 
        return (t.charge, t.activeCharge, t.value, t.incrementalValue, t.activationThreshold);
    }

    /// @notice Get the Status and additional Data associated with a Token
    /// @dev    The Active Status is different from the Activated Status in that once Activated,
    ///         the latter will always remain true, even if the Token is Deactivated.
    ///         Contributors may still be greater than zero after Discharge if this is a Contract Token,
    ///         as the first contributor will be an ERC721 address until the underlying Token is Recalled.
    /// @param  tokenId The ID of the token whose Data is to be returned
    /// @return active The Active Status of the Token
    /// @return restricted The Restricted Status of the Token
    /// @return links The number of Tokens this Token Links to
    /// @return contributors The number of addresses that have Contributed to the Token
    /// @return data The Token's Data
    function tokenData(uint256 tokenId) public view tokenExists(tokenId) returns(bool active, bool restricted, uint256 links, uint256 contributors, bytes memory data) {
        Token storage t = _tokens[tokenId]; 
        return (t.active, t.restricted, t.links.length, t.contributors.length, t.data);
    }

    // Create Token
    function _createToken(address creator, uint256 incrementalValue, uint256 activationThreshold, bytes calldata data) internal returns(uint256) {      
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        emit Create(tokenId);
        
        _mint(creator, tokenId);

        Token storage t = _tokens[tokenId];
        
        t.incrementalValue = incrementalValue;
        t.activationThreshold = activationThreshold;

        t.data = data;

        return tokenId;
    }

    /// @notice Creates a new Token.
    ///         Linking to a plane other than the 4 elemental planes (4-7; fire, air, earth, water) requires a Coin transfer:
    ///             void, karmic, and kaotic planes (1-3; void, karma, kaos): 5x Coin Rate
    ///             paraelemental planes (8-11; ice, lightning, metal, nature): 1x Coin Rate
    ///             energy planes (12-16; harmony, discord, entropy, exergy, magick): 25x Coin Rate
    ///             ethereal planes (17-18; aether, world): 100x Coin Rate
    /// @dev    Data stored with the Token cannot be updated.
    /// @param  incrementalValue the Value (in wei), required to be sent with each Coin used to Charge the Token. Can be 0 or a multiple of the Minimum Incremental Value
    /// @param  activationThreshold the number of Coins required for the Token to be Activated (decimals excluded)
    /// @param  restricted Boolean indicating whether a address must be Whitelisted to Contribute to a Token
    /// @param  plane The planar Token to link to
    /// @param  data Optional data to store with the Token
    function createToken(uint256 incrementalValue, uint256 activationThreshold, bool restricted, uint256 plane, bytes calldata data) public payable returns(uint256) {
        uint256 tokenId = _createToken(_msgSender(), incrementalValue, activationThreshold * _coinDecimals, data);
        Token storage t = _tokens[tokenId];

        if (msg.value > 0) {
            _createValue(tokenId, msg.value);
        }

        if (plane > 0) {
            require(plane <= 18, "DiGiL: Invalid Plane");
            if (plane < 4) {
                _coinsFromSender(_coinRate * 5);
            } else if (plane > 16) {
                _coinsFromSender(_coinRate * 100);
            } else if (plane > 11) {
                _coinsFromSender(_coinRate * 25);
            } else if (plane > 7) {
                _coinsFromSender(_coinRate);
            }
            t.links.push(plane);
            t.linkEfficiency[plane] = LinkEfficiency(100, 0);
            emit Link(tokenId, plane);
        }
        
        if (restricted) {
            require(msg.value >= t.incrementalValue && msg.value >= _incrementalValue, "DiGiL: Insufficient Funds");
            t.restricted = true;
            emit Restrict(tokenId);
        }

        return tokenId;
    }

    /// @notice Add accounts to a Token's Whitelist.
    ///         Once an address has been whitelisted, it cannot be removed.
    ///         If no whitelisted addresses are supplied, the Token's Whitelist is disabled.
    ///         Requires a Value sent greater than or equal to the larger of the Token's Incremental Value or the Minimum Incremental Value. 
    /// @param  tokenId The ID of the 
    /// @param  whitelisted The addresses to Whitelist
    function restrictToken(uint256 tokenId, address[] memory whitelisted) public payable approved(tokenId) {
        uint256 value = msg.value;
        Token storage t = _tokens[tokenId];

        bool restrict = whitelisted.length > 0;
        bool wasRestricted = t.restricted;
        if (restrict != wasRestricted) {
            t.restricted = restrict;
            if (restrict) {
                require(value >= t.incrementalValue && value >= _incrementalValue, "DiGiL: Insufficient Funds");
                emit Restrict(tokenId);
            }
        }

        if (value > 0) {
            _createValue(tokenId, value);
        }

        mapping(address => TokenContribution) storage contributions = t.contributions;

        uint256 accountIndex;
        uint256 accountsLength = whitelisted.length;
        for (accountIndex; accountIndex < accountsLength; accountIndex++) {
            address account = whitelisted[accountIndex];
            contributions[account].whitelisted = true;
            emit Whitelist(account, tokenId);
        }        
    }

    /// @notice Updates an existing Token. Message sender must be approved for this Token.
    ///         In order for the Incremental Value or Activation Threshold to be updated, the Token must have 0 Charge.
    ///         In order for the Token Data or URI to be updated a Value must be sent of at least the Token's Incremental Value plus the Minimum Incremental Value.
    ///         In addition, for a Data update, a transfer of 10000 Coins per Coin Rate; for a URI update, 100000 Coins per Coin Rate.
    /// @param  tokenId The ID of the Token to Update
    /// @param  incrementalValue The Value (in wei), required to be sent with each Coin used to Charge the Token. Can be 0 or a multiple of the Minimum Incremental Value
    /// @param  activationThreshold The number of Coins required for the Token to be Activated (decimals excluded)
    /// @param  data The updated Data for the Token (only updated if length > 0)
    /// @param  data The updated URI for the Token (only updated if length > 0) 
    function updateToken(uint256 tokenId, uint256 incrementalValue, uint256 activationThreshold, bytes calldata data, string calldata uri) public payable approved(tokenId) {
        Token storage t = _tokens[tokenId];
        activationThreshold *= _coinDecimals;

        if (t.charge > 0) {
            require(t.incrementalValue == incrementalValue && t.activationThreshold == activationThreshold, "DiGiL: Cannot Update Charged Token");
        }

        bool overwriteData = bytes(data).length > 0;
        if (overwriteData) {
            _coinsFromSender(_coinRate * 1000);
        }

        bool overwriteUri = bytes(uri).length > 0;
        if (overwriteUri && !_ownerIsSender()) {
            _coinsFromSender(_coinRate * 10000);
        }

        uint256 minimumValue = (overwriteData || overwriteUri) ? (t.incrementalValue + _incrementalValue) : 0;
        require(msg.value >= minimumValue, "DiGiL: Insufficient Funds");
        _addValue(msg.value);

        t.incrementalValue = incrementalValue;
        t.activationThreshold = activationThreshold;

        if (overwriteUri) {
            t.uri = uri;
        }

        if (overwriteData) {
            t.data = data;
        }

        emit Update(tokenId);
    }

    // Charge Token
    function _chargeActiveToken(address contributor, uint256 tokenId, uint256 coins, uint256 activeCoins, uint256 value, bool link) internal {
        Token storage t = _tokens[tokenId];

        uint256[] storage links = t.links;
        uint256 linksLength = links.length;

        if (linksLength == 0 || link) {

            t.activeCharge += coins + activeCoins;
            emit ActiveCharge(tokenId, coins + activeCoins);

        } else {    

            uint256 linkedValue = value / linksLength;   
            uint256 linkIndex;
            for(linkIndex; linkIndex < linksLength; linkIndex++) {                
                uint256 linkId = links[linkIndex];
                uint256 linkedCoins = coins / 100 * t.linkEfficiency[linkId].base;
                uint256 bonusCoins = coins / 100 * t.linkEfficiency[linkId].affinityBonus;
                bool charged = _exists(linkId) && _chargeToken(contributor, linkId, linkedCoins, bonusCoins, linkedValue, true);
                if (charged) {
                    value -= linkedValue;
                } else {
                    t.activeCharge += linkedCoins;
                    emit ActiveCharge(linkId, linkedCoins);
                }
            }

        }

        if (value > 0) {
            _addDistribution(ownerOf(tokenId), value, 0);
        }
    }

    function _chargeToken(address contributor, uint256 tokenId, uint256 coins, uint256 activeCoins, uint256 value, bool link) internal returns(bool) {
        Token storage t = _tokens[tokenId];

        TokenContribution storage c = t.contributions[contributor];
        bool whitelisted = !t.restricted || c.whitelisted;

        uint256 incrementalValue = t.incrementalValue;
        // The minimum Value required to Charge this Token based on the number of Coins specified
        uint256 minimumValue = incrementalValue * coins / _coinDecimals;

        // The minimum number of Coins required to Charge this Token based on the Value specified
        // If the Incremental Value is 0, all Coins will be used to charge this Token
        uint256 minimumCoins = coins;
        if (incrementalValue > 0) {
            minimumCoins = value < incrementalValue || value == 0 ? coins : value / incrementalValue * _coinDecimals;

            // Minimum value cannot be less than the Token's Incremental Value
            if (minimumValue < incrementalValue) {
                minimumValue = incrementalValue;
            }
        }

        // Minimum number of Coins cannot be less than 1
        if (minimumCoins < _coinDecimals) {
            minimumCoins = _coinDecimals;
        }

        if (link) {
            
            // Linked Charging can use Active Coins to meet the requirements of the minimum Charge  
            // If the Contributor isn't Whitelisted, or not enough Coins are supplied by the Link, the Token will not be Charged
            if (!whitelisted || minimumCoins > (coins + activeCoins)) {
                return false;
            }
            minimumValue = value;

        } else {

            require(whitelisted, "DiGiL: Restricted");            
            require(value >= minimumValue, "DiGiL: Insufficient Funds");
            _coinsFromSender(coins);

        }

        if (t.active) {

            _chargeActiveToken(contributor, tokenId, coins, activeCoins, value, link);

        } else {

            if (!c.exists) {
                c.exists = true;
                t.contributors.push(contributor);
            }            

            if (minimumValue > 0) {
                c.value += minimumValue;
                emit Contribute(contributor, tokenId, minimumValue);
            }
            
            if (value > minimumValue) {
                t.value += value - minimumValue;
                emit ContributeValue(contributor, tokenId, value - minimumValue);
            }

            // If the number of Coins supplied is greater than the minimum required, any excess are added to the Token's Active Charge.
            if (coins > minimumCoins) {
                t.activeCharge += coins - minimumCoins;
                emit ActiveCharge(tokenId, coins - minimumCoins);
                coins = minimumCoins;
            }

            c.charge += coins;
            t.charge += coins;
            emit Charge(contributor, tokenId, coins);

        }

        return true;
    }

    /// @notice Charge Token.
    ///         Requires a Value sent greater than or equal to the Token's Incremental Value for each Coin.
    /// @param  tokenId The ID of the Token to Charge
    /// @param  coins The Coins used to Charge the Token (decimals excluded)
    function chargeToken(uint256 tokenId, uint256 coins) public payable {
        chargeTokenAs(_msgSender(), tokenId, coins * _coinDecimals);
    }

    /// @notice Charge Token on behalf of a Contributor.
    ///         Requires a Value sent greater than or equal to the Token's Incremental Value for each Coin.
    /// @param  contributor The address to record as the contributor of this Charge
    /// @param  tokenId The ID of the Token to Charge
    /// @param  coins The Coins used to Charge the Token
    function chargeTokenAs(address contributor, uint256 tokenId, uint256 coins) public payable operatorEnabled(contributor) {
        require(coins >= _coinDecimals, "DiGiL: Insufficient Charge");
        _chargeToken(contributor, tokenId, coins, 0, msg.value, false);
    }

    // Token Distribution
    function _distribute(uint256 tokenId, bool discharge) internal {
        Token storage t = _tokens[tokenId];
        uint256 tCharge = t.charge;
        t.charge = 0;
        uint256 tValue = t.value;
        t.value = 0;

        uint256 distribution;
        uint256 cIndex;
        uint256 cLength = t.contributors.length;
        uint256 incrementalValue = tCharge >= _coinDecimals ? tValue / (tCharge / _coinDecimals) : 0;
        for (cIndex; cIndex < cLength; cIndex++) {
            address contributor = t.contributors[cIndex];
            if (contributor == address(0)) {
                break;
            }

            TokenContribution storage contribution = t.contributions[contributor];
            bool distributed = contribution.distributed;
            contribution.distributed = true;

            ContractToken storage contractToken = _contractTokens[contributor][tokenId];
            if (contractToken.tokenId != 0) {

                contractToken.recallable = true;

            } else if (!distributed) {

                if (discharge) {

                    _addValue(contributor, contribution.value, contribution.charge);

                } else {

                    distribution += contribution.value;
                    uint256 distributableTokenValue = incrementalValue * contribution.charge / _coinDecimals;
                    tValue -= distributableTokenValue;
                    _addValue(contributor, distributableTokenValue, 1 * _coinDecimals);

                }

            }
        }
        
        if (discharge) {

            _addDistribution(ownerOf(tokenId), tValue, 0);

        } else {

            if (tCharge > 0) {
                t.activeCharge += tCharge;
                emit ActiveCharge(tokenId, tCharge);
            }
            _addDistribution(ownerOf(tokenId), distribution, 0);
            _addValue(tValue);
            
        }
    }

    // Discharge Token
    function _discharge(uint256 tokenId, bool burn) internal {
        Token storage t = _tokens[tokenId];
        require(msg.value >= _incrementalValue && msg.value >= t.incrementalValue, "DiGiL: Insufficient Funds");
        _addValue(msg.value);
        
        _distribute(tokenId, burn || !t.active);

        address contractTokenAddress;

        uint256 cIndex;
        uint256 cLength = t.contributors.length;
        for (cIndex; cIndex < cLength; cIndex++) {
            address contributor = t.contributors[cIndex];
            if (contributor == address(0)) {
                break;
            }
            
            TokenContribution storage contribution = t.contributions[contributor];

            contribution.charge = 0;
            contribution.value = 0;
            contribution.exists = false;
            contribution.distributed = false;

            if (cIndex == 0) {
                ContractToken storage contractToken =  _contractTokens[contributor][tokenId];
                if (contractToken.tokenId != 0) {
                    contractTokenAddress = contributor;
                    contractToken.recallable = false;  
                    if (burn) {
                        contractToken.tokenId = 0;
                    }                    
                }
            }
        }

        delete t.contributors;

        emit Discharge(tokenId);

        if (burn) {

            delete _tokens[tokenId];
            _burn(tokenId);

        } else if (contractTokenAddress != address(0)) {

            t.contributors.push(contractTokenAddress);

        }
    }

    /// @notice Discharge an existing Token and reset all Contributions.
    ///         If the Token has been Activated: Any Contributed Value that has not yet been Distributed will be Distributed.
    ///         If the Token has not been Activated: Any Contributed Value that has not yet been Distributed will be returned to its Contributors, any additional Token Value to its owner.
    ///         Requires a Value sent greater than or equal to the larger of the Token's Incremental Value or the Minimum Incremental Value.
    /// @param  tokenId The ID of the Token to Discharge
    function dischargeToken(uint256 tokenId) public payable approved(tokenId) {
        _discharge(tokenId, false);
    }

    /// @notice Destroy (burn), an existing Token.
    ///         If the Token has been Activated: Any Contributed Value that has not yet been Distributed will be Distributed.
    ///         If the Token has not been Activated: Any Contributed Value that has not yet been Distributed will be returned to its Contributors, any additional Token Value to its owner.
    ///         Any Contract Tokens Linked to this Token that have yet to be Recalled, cannot be Recalled.
    ///         Requires a Value sent greater than or equal to the larger of the Token's Incremental Value or the Minimum Incremental Value.
    /// @param  tokenId The ID of the Token to Destroy
    function destroyToken(uint256 tokenId) public payable approved(tokenId) {        
        _discharge(tokenId, true);
        emit Destroy(tokenId);
    }

    /// @notice Activate an Inactive Token, Distributes Value, Coins, and execute Links.
    ///         Requires the Token have a Charge greater than or equal to the Token's Activation Threshold.
    /// @param  tokenId The ID of the Token to activate.
    function activateToken(uint256 tokenId) public payable approved(tokenId) {
        Token storage t = _tokens[tokenId];
        require(t.active == false && t.charge >= t.activationThreshold, "DiGiL: Token Cannot Be Activated");

        if (msg.value > 0) {
            _createValue(tokenId, msg.value);
        }

        t.active = true;
        emit Activate(tokenId);

        _distribute(tokenId, false);
    }

    /// @notice Deactivates an Active Token.
    ///         Requires the Token have zero Charge, and a Value sent greater than or equal to the Token's Incremental Value.
    /// @param  tokenId The ID of the token to Deactivate
    function deactivateToken(uint256 tokenId) public payable approved(tokenId) {
        Token storage t = _tokens[tokenId];
        require(t.active == true && t.charge == 0, "DiGiL: Token Cannot Be Deactivated");
        require(msg.value >= t.incrementalValue, "DiGiL: Insufficient Funds");

        if (msg.value > 0) {
            _addValue(msg.value);
        }

        t.active = false;
    }

    /// @notice Links two Tokens together in order to generate or transfer Coins on Charge or Token Activation.
    ///         Requires a Value greater than or equal to the larger of the source and destination Token's Incremental Value.
    ///         Any Value contributed is split between and added to the source and destination Token.
    ///         Requires a summation of Coins at the Coin Rate depending on the number of existing Links.
    ///         An Efficiency of 1 is meant to indicate a Coin generation or transfer of 1%; 100 would be 100%; 200 would be 200%; et. cetera.
    /// @param  tokenId The ID of the Token to Link (source)
    /// @param  linkId The ID of the Token to Link to (destination)
    /// @param  efficiency The Efficiency of the Link
    function linkToken(uint256 tokenId, uint256 linkId, uint8 efficiency) public payable approved(tokenId) {
        Token storage t = _tokens[tokenId];
        uint8 baseEfficiency = t.linkEfficiency[linkId].base;
        uint256 bonusEfficiency = t.linkEfficiency[linkId].affinityBonus;

        require(tokenId != linkId && linkId > 18 && efficiency > baseEfficiency, "DiGiL: Invalid Link");
        
        Token storage d = _tokens[linkId];
        require(!d.restricted || d.contributions[_msgSender()].whitelisted, "DiGiL: Restricted");

        uint256 value = msg.value;
        require(value >= (t.incrementalValue + d.incrementalValue), "DiGiL: Insufficient Funds");
        if (value > 0) {
            _createValue(tokenId, value / 2);
            _createValue(linkId, value / 2);
        }

        uint256 sourcePlane = t.links[0];
        uint256 destinationPlane = d.links[0];
        if (sourcePlane > 0 && sourcePlane <= 18 && destinationPlane > 0 && destinationPlane <= 18) {            
            uint256 bonus = _affinityBonus(sourcePlane, destinationPlane, efficiency);
            bonusEfficiency = bonus > bonusEfficiency ? bonus : bonusEfficiency;
        }

        t.linkEfficiency[linkId].base = efficiency;
        t.linkEfficiency[linkId].affinityBonus = bonusEfficiency;
        
        if (baseEfficiency == 0) {
            t.links.push(linkId);
        }

        emit Link(tokenId, linkId, efficiency, bonusEfficiency);
        
        uint256 linkScale = 200 / t.links.length;
        uint256 e = efficiency > linkScale ? efficiency - linkScale : 0;
        _coinsFromSender((efficiency + (e * (e + 1) / 2)) * _coinRate);
    }

    function _affinityBonus(uint256 sourceId, uint256 destinationId, uint8 efficiency) internal view returns (uint256 _bonus) {
        bytes storage s = _tokens[sourceId].data;
        bytes storage d = _tokens[destinationId].data;

        if (s[1] == d[0] || s[2] == d[0]) {
            _bonus = uint256(efficiency) * 2;
        } else if (sourceId == destinationId || sourceId > 16) {
            _bonus = uint256(efficiency);
        } else if (s[3] == d[0]) {
            _bonus = uint256(efficiency) / 2;
        }

        if (_bonus == 0) {
            return _bonus;
        }

        if (sourceId > 16) {
            _bonus *= 4;
        } else if (sourceId > 11 || destinationId == 18) {
            _bonus *= 2;
        }

        if (_tokens[sourceId].activeCharge >= _tokens[destinationId].activeCharge) {
            _bonus /= 2;
        }

        return _bonus;
    }

    /// @notice Unlink Tokens
    /// @param  tokenId The ID of the Token to Unlink (source)
    /// @param  linkId The ID of the Token to Unlink (destination)
    function unlinkToken(uint256 tokenId, uint256 linkId) public approved(tokenId) {
        Token storage t = _tokens[tokenId];
        require(linkId > 0 && t.linkEfficiency[linkId].base > 0, "DiGiL: Invalid Link");

        t.linkEfficiency[linkId] = LinkEfficiency(0, 0);

        uint256[] storage links = t.links;
        uint256 linkIndex;
        uint256 linksLength = links.length;
        for (linkIndex; linkIndex < linksLength; linkIndex++) {
            uint256 lId = links[linkIndex];
            if (lId == linkId) {
                links[linkIndex] = links[linksLength - 1];
                links.pop();
                emit Unlink(tokenId, linkId);
                break;
            }
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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