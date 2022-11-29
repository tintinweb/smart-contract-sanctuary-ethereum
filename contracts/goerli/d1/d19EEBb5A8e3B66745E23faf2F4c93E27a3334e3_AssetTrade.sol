/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;

interface IERC20 {
    function decimals() external view returns (uint8);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IFeed {
    function decimals() external view returns (uint8);	
    function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Ownable is Initializable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init_unchained() internal initializer {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AssetTrade is Initializable,Ownable {
    using SafeMath for uint256;
    bytes32 constant public NODEMSG = keccak256("nodeMsg");
    bytes32 constant public NFTMSG = keccak256("nftMsg");
    bytes32 constant public TOKENMSG = keccak256("tokenMsg");
    mapping(bytes32 => Data) dataMsg;
    uint256 public tradeNum;
    mapping(uint256 => TradeMsg) public tradeMsg;
    uint256 public feeRate;
    mapping(address => uint256) public tokenFee;
    bytes32 public DOMAIN_SEPARATOR;
    address public signAddr;
    mapping(address => address) public tokenFeed;
    uint256 public rangeRate;
    address public router;
    address public HGBPAddr;
    address public stableToken;
    

    event AddNodeAddr(address[] nodeAddrs);
    event DeleteNodeAddr(address[] nodeAddrs);
    event AddNFTAddr(address[] nodeAddrs);
    event DeleteNFTAddr(address[] nodeAddrs);
    event AddTokenAddr(address[] nodeAddrs);
    event DeleteTokenAddr(address[] nodeAddrs);
    event UpdateRate(uint256 _feeRate);
    event SellAssets(uint256 index, address sellAddr, address nftAddr, uint256 nftTokenId, uint256 price, uint256 sta, address[] tokenAddr);
    event CancleSellAssets(uint256 index, uint256 sta);
    event UpdateSellAssets(uint256 index, uint256 price, address[] tokenAddr);
    event BuyAssets(uint256 index, address buyAddr, address paymentToken, uint256 paymentAmount, uint256 fee, uint256 sta);
    event UpdateTrade(uint256 index, uint256 sta); 
    event VoteAssetsTrade(uint256 index, address voter, uint256 voteSta);

    struct Data {
        uint256 num;                           
        mapping(address => uint256) addrIndex;  
        mapping(uint256 => address) indexAddr;
        mapping(address => bool) addrSta;
    }

    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    struct TradeMsg {
        address sellAddr;
        address buyAddr;
        address nftAddr;
        uint256 nftTokenId;
        address[] tokenAddrs;
        mapping(address => bool) tokenSta;
        uint256 price;
        address paymentToken;
        uint256 paymentAmount;
        uint256 fee;
        uint256 sta;
        address[] agreeAddr;
        address[] againstAddr;
        mapping(address => bool) voteSta;
    }

    function init(
        address _signAddr,
        address _router,
        uint256 _feeRate,
        uint256 _rangeRate,
        address[] calldata _nodeAddrs,
        address[] calldata _nftAddrs,
        address[] calldata _tokenAddrs,
        address[] calldata _tokenFeeds
    )  external initializer{
        __Ownable_init_unchained();
        __AssetTrade_init_unchained(_signAddr, _router, _feeRate, _rangeRate, _nodeAddrs, _nftAddrs, _tokenAddrs, _tokenFeeds);
    }

    function __AssetTrade_init_unchained(
        address _signAddr,
        address _router,
        uint256 _feeRate,
        uint256 _rangeRate,
        address[] calldata _nodeAddrs,
        address[] calldata _nftAddrs,
        address[] calldata _tokenAddrs,
        address[] calldata _tokenFeeds
    ) internal initializer{
        signAddr = _signAddr;
        router = _router;
        feeRate = _feeRate;
        rangeRate = _rangeRate;
        addNodeAddr(_nodeAddrs);
        addNFTAddr(_nftAddrs);
        addTokenAddr(_tokenAddrs, _tokenFeeds);
        uint chainId;
        assembly {
            chainId := chainId
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(uint256 chainId,address verifyingContract)'),
                chainId,
                address(this)
            )
        );
    }

    receive() payable external{

    }

    fallback() payable external{

    }

    function updateRangeRate(uint256 _rangeRate) external onlyOwner{
        rangeRate = _rangeRate;
    }

    function updatePairAddr(address _HGBPAddr, address _stableToken) external onlyOwner{
        HGBPAddr = _HGBPAddr;
        stableToken = _stableToken;
    }

    function updateSignAddr(address _signAddr) external onlyOwner{
        signAddr = _signAddr;
    }

    function addNodeAddr(address[] calldata _nodeAddrs) public onlyOwner{
        Data storage _dataMsg = dataMsg[NODEMSG];
        _addAddr(_nodeAddrs, _dataMsg);
        emit AddNodeAddr(_nodeAddrs);
    }

    function deleteNodeAddr(address[] calldata _nodeAddrs) external onlyOwner{
        Data storage _dataMsg = dataMsg[NODEMSG];
        _deleteAddr(_nodeAddrs, _dataMsg);
        emit DeleteNodeAddr(_nodeAddrs);
    }
    
    function addNFTAddr(address[] calldata _nftAddrs) public onlyOwner{
        Data storage _dataMsg = dataMsg[NFTMSG];
        _addAddr(_nftAddrs, _dataMsg);
        emit AddNFTAddr(_nftAddrs);
    }

    function deleteNFTAddr(address[] calldata _nftAddrs) external onlyOwner{
        Data storage _dataMsg = dataMsg[NFTMSG];
        _deleteAddr(_nftAddrs, _dataMsg);
        emit DeleteNFTAddr(_nftAddrs);
    }
    
    function addTokenAddr(address[] calldata _tokenAddrs, address[] calldata _tokenFeeds) public onlyOwner{
        Data storage _dataMsg = dataMsg[TOKENMSG];
        _addAddr(_tokenAddrs, _dataMsg);
        for(uint i= 0; i<_tokenAddrs.length; i++){
            tokenFeed[_tokenAddrs[i]] = _tokenFeeds[i];
        }
        emit AddTokenAddr(_tokenAddrs);
    }

    function deleteTokenAddr(address[] calldata _tokenAddrs) external onlyOwner{
        Data storage _dataMsg = dataMsg[TOKENMSG];
        _deleteAddr(_tokenAddrs, _dataMsg);
        emit DeleteTokenAddr(_tokenAddrs);
    }
    
    function withdrawFee(address[] calldata _tokenAddrs, address receiveAddr) external onlyOwner{
        for(uint i= 0; i<_tokenAddrs.length; i++){
            if(_tokenAddrs[i] == address(0x00)){
                payable(receiveAddr).transfer(tokenFee[_tokenAddrs[i]]);
            }else {
                IERC20(_tokenAddrs[i]).transfer(receiveAddr, tokenFee[_tokenAddrs[i]]);
            }
            tokenFee[_tokenAddrs[i]] = 0;
        }
    }
    
    function updateRate(uint256 _feeRate) external onlyOwner{
        feeRate = _feeRate;
        emit UpdateRate(_feeRate);
    }
    
    function sellAssets(
        address nftAddr,
        uint256 nftTokenId,
        address[] calldata tokenAddrs,
        uint256 price
    )
        external
    {   
        require(dataMsg[NFTMSG].addrSta[nftAddr], "Does not support current nft"); 
        IERC721(nftAddr).transferFrom(msg.sender, address(this), nftTokenId);
        uint256 _tradeNum = ++tradeNum;
        TradeMsg storage _tradeMsg = tradeMsg[_tradeNum];
        address tokenAddr;
        for(uint i= 0; i<tokenAddrs.length; i++){
            tokenAddr = tokenAddrs[i];
            require(dataMsg[TOKENMSG].addrSta[tokenAddr], "Does not support current token payment"); 
            _tradeMsg.tokenAddrs.push(tokenAddr);
            _tradeMsg.tokenSta[tokenAddr] = true;
        }
        _tradeMsg.sellAddr = msg.sender;
        _tradeMsg.nftAddr = nftAddr;
        _tradeMsg.nftTokenId = nftTokenId;
        _tradeMsg.price = price;
        _tradeMsg.sta = 1;
        emit SellAssets(_tradeNum, _tradeMsg.sellAddr, nftAddr, nftTokenId, price, _tradeMsg.sta, tokenAddrs);
    }

    function cancleSellAssets(uint256[] calldata indexes) external{   
        for(uint i= 0; i<indexes.length; i++){
            TradeMsg storage _tradeMsg = tradeMsg[indexes[i]];
            require(_tradeMsg.sellAddr == msg.sender, "The caller is not the owner"); 
            require(_tradeMsg.sta == 1, "The current trade status cannot be canceled"); 
            _tradeMsg.sta = 2;
            IERC721(_tradeMsg.nftAddr).transferFrom(address(this), msg.sender, _tradeMsg.nftTokenId);
            emit CancleSellAssets(indexes[i], 2);
        }
    }
    
    function updateSellAssets(uint256 index, address[] calldata tokenAddrs, uint256 price) external{   
        TradeMsg storage _tradeMsg = tradeMsg[index];
        require(_tradeMsg.sellAddr == msg.sender, "The caller is not the owner"); 
        require(_tradeMsg.sta == 1, "The current trade status cannot be updated"); 
        for(uint i= 0; i<_tradeMsg.tokenAddrs.length; i++){
            _tradeMsg.tokenSta[_tradeMsg.tokenAddrs[i]] = false;
        }
        delete _tradeMsg.tokenAddrs;
        address tokenAddr;
        for(uint i= 0; i<tokenAddrs.length; i++){
            tokenAddr = tokenAddrs[i];
            require(dataMsg[TOKENMSG].addrSta[tokenAddr], "Does not support current token payment"); 
            _tradeMsg.tokenAddrs.push(tokenAddr);
            _tradeMsg.tokenSta[tokenAddr] = true;
        }
        _tradeMsg.price = price;
        emit UpdateSellAssets(index, price, tokenAddrs);
    }
    
    function buyAssets(
        uint256 index, 
        address buyAddr,
        address paymentToken,
        uint256 paymentAmount,
        uint256 expiration,
        uint8 vs,
        bytes32[] calldata rssMetadata
    )   
        payable 
        external
    {   
        require( buyAddr == msg.sender , "not buyer");
        require( block.timestamp<= expiration, "The transaction exceeded the time limit");
        bytes32 digest = getDigest(index, buyAddr, paymentToken, paymentAmount, expiration);
        bool result = verifySign(digest,Sig(vs, rssMetadata[0], rssMetadata[1]));
        require(result, "Signature error");
        TradeMsg storage _tradeMsg = tradeMsg[index];
        uint256 _amount;
        if(HGBPAddr == paymentToken){
            address[] memory path = new address[](2);
            path[0] = HGBPAddr;
            path[1] = stableToken;
            uint[] memory amounts = IUniswapRouter(router).getAmountsOut(10**18,path);
            _amount = amounts[1].mul(10000).mul(paymentAmount);
        }else {
            IFeed feed =  IFeed(tokenFeed[paymentToken]);
            (, int256 answer, , ,) = feed.latestRoundData();
            _amount = uint256(answer).mul(10 ** (uint256(22).sub(feed.decimals()))).mul(paymentAmount);
        }
        require(_tradeMsg.price.mul(10000 + rangeRate) > _amount  && _tradeMsg.price.mul(10000 - rangeRate) < _amount, "price error"); 
        require(_tradeMsg.tokenSta[paymentToken], "payment error"); 
        require(_tradeMsg.sta == 1, "not purchase"); 
        _tradeMsg.sta = 3;
        _tradeMsg.paymentToken = paymentToken;
        _tradeMsg.paymentAmount = paymentAmount;
        if(paymentToken == address(0x00)){
            require(paymentAmount == msg.value, "value is incorrect"); 
        }else {
            require(msg.value == 0, "value should be 0"); 
            require(IERC20(paymentToken).transferFrom(msg.sender, address(this), paymentAmount), "Token transfer failed");
        }
        _tradeMsg.fee = paymentAmount.mul(feeRate).div(10000);
        _tradeMsg.buyAddr = msg.sender;
        emit BuyAssets(index, _tradeMsg.buyAddr, paymentToken, paymentAmount, _tradeMsg.fee, 3);
    }
  
    function voteAssetsTrade(uint256[] calldata indexes,  uint256[] calldata voteStas) external{   
        require(dataMsg[NODEMSG].addrSta[msg.sender], "The caller is not a node address");
        require(indexes.length == voteStas.length, "The parameter length mismatch");
        for(uint i= 0; i<indexes.length; i++){
            TradeMsg storage _tradeMsg = tradeMsg[indexes[i]];
            if(!_tradeMsg.voteSta[msg.sender] && _tradeMsg.sta > 2){
                _tradeMsg.voteSta[msg.sender] = true;
                if(voteStas[i] == 0){
                    _tradeMsg.agreeAddr.push(msg.sender);
                }else{
                    _tradeMsg.againstAddr.push(msg.sender);
                }
                emit VoteAssetsTrade(indexes[i], msg.sender, voteStas[i]);
            }
            uint256 num = dataMsg[NODEMSG].num;
            if(_tradeMsg.agreeAddr.length > num/2 && _tradeMsg.sta ==3){
                _tradeMsg.sta = 4;
                uint256 amount = _tradeMsg.paymentAmount.sub(_tradeMsg.fee);
                tokenFee[_tradeMsg.paymentToken] += _tradeMsg.fee;
                if(_tradeMsg.paymentToken == address(0x00)){
                    payable(_tradeMsg.sellAddr).transfer(amount);
                }else {
                    require(IERC20(_tradeMsg.paymentToken).transfer(_tradeMsg.sellAddr, amount), "Token transfer failed");
                }
                IERC721(_tradeMsg.nftAddr).transferFrom(address(this), _tradeMsg.buyAddr, _tradeMsg.nftTokenId);
                emit UpdateTrade(indexes[i], 4);
            }else if(_tradeMsg.againstAddr.length > num/2 && _tradeMsg.sta ==3){
                _tradeMsg.sta = 5;
                if(_tradeMsg.paymentToken == address(0x00)){
                    payable(_tradeMsg.buyAddr).transfer(_tradeMsg.paymentAmount);
                }else {
                    require(IERC20(_tradeMsg.paymentToken).transfer(_tradeMsg.buyAddr, _tradeMsg.paymentAmount), "Token transfer failed");
                }
                IERC721(_tradeMsg.nftAddr).transferFrom(address(this), _tradeMsg.sellAddr, _tradeMsg.nftTokenId);
                emit UpdateTrade(indexes[i], 5); 
            }
        }
    }

    function queryTradeVote(
        uint256 index
    ) 
        external 
        view 
        returns (
            address[] memory tokenAddrs, 
            address[] memory agreeAddrs, 
            address[] memory againstAddrs
        ) 
    {
        TradeMsg storage _tradeMsg = tradeMsg[index];
        (tokenAddrs, agreeAddrs, againstAddrs) = (_tradeMsg.tokenAddrs, _tradeMsg.agreeAddr, _tradeMsg.againstAddr);
        
    }

    function queryFee() external view returns (address[] memory, uint256[] memory) {
        Data storage _dataMsg = dataMsg[TOKENMSG];
        address[] memory _addrArray = new address[](_dataMsg.num);
        uint256[] memory _valueArray = new uint256[](_dataMsg.num);
        uint256 j;
        if (_dataMsg.num > 0){
            for (uint256 i = 1; i <= _dataMsg.num; i++) {
                _addrArray[j] = _dataMsg.indexAddr[i];
                _valueArray[j] = tokenFee[_addrArray[j]];
                j++;
            }
        }
        return (_addrArray, _valueArray);
    }

    function queryDataMsg(
        bytes32 _data,
        uint256 _page,
        uint256 _limit
    )
        external
        view
        returns(
            address[] memory,
            uint256 
        )
    {   
        Data storage _dataMsg = dataMsg[_data];  
        (address[] memory addrs, uint256 _num) = _obtainLianchuangMsg(_dataMsg, _page, _limit);
        return (addrs, _num);
    }

    function _obtainLianchuangMsg(Data storage _dataMsg, uint256 _page, uint256 _limit) internal view returns(address[] memory addrs, uint256 _num){
        _num = _dataMsg.num;
        if (_limit > _num){
            _limit = _num;
        }
        if (_page<2){
            _page = 1;
        }
        _page--;
        uint256 start = _page.mul(_limit);
        uint256 end = start.add(_limit);
        if (end > _num){
            end = _num;
            _limit = end.sub(start);
        }
        start = _num - start;
        end = _num - end; 
        addrs = new address[](_limit);
        if (_num > 0){
            uint256 j;
            for (uint256 i = start; i > end; i--) {
                addrs[j] = _dataMsg.indexAddr[i];
                j++;
            }
        }
    }

    function verifySign(bytes32 _digest,Sig memory _sig) internal view returns (bool)  {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(prefix, _digest));
        address _nodeAddr = ecrecover(hash, _sig.v, _sig.r, _sig.s);
        require(_nodeAddr !=address(0),"Illegal signature");
        return signAddr == _nodeAddr;
    }
    
    function getDigest(uint256 index, address buyAddr, address paymentToken, uint256 paymentAmount, uint256 expiration) internal view returns(bytes32 digest){
        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(index, buyAddr, paymentToken, paymentAmount, expiration))
            )
        );
    }

    function _addAddr(address[] memory _addrs, Data storage _data) internal{
        for (uint256 i = 0; i< _addrs.length; i++){
            address _addr = _addrs[i];
            require(!_data.addrSta[_addr], "The address has already been added");
            _data.addrSta[_addr] = true;
            uint256 _addrIndex = _data.addrIndex[_addr];
            if (_addrIndex == 0){
                _addrIndex = ++_data.num;
                _data.addrIndex[_addr] = _addrIndex;
                _data.indexAddr[_addrIndex] = _addr;
            }
        }
    }

    function _deleteAddr(address[] memory _addrs, Data storage _data) internal{
        for (uint256 i = 0; i< _addrs.length; i++){
            address _addr = _addrs[i];
            require(_data.addrSta[_addr], "This address not added");
            _data.addrSta[_addr] = false;
            uint256 _addrIndex = _data.addrIndex[_addr];
            if (_addrIndex > 0){
                uint256 _num = _data.num;
                address _lastAddr = _data.indexAddr[_num];
                _data.addrIndex[_lastAddr] = _addrIndex;
                _data.indexAddr[_addrIndex] = _lastAddr;
                _data.addrIndex[_addr] = 0;
                _data.indexAddr[_num] = address(0x0);
                _data.num--;
            }
        }
    }
  
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}