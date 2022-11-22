/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function mint(address to, uint256 value) external returns (bool);
    function burn(uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
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
     * @dev Initializes the contract setting the management contract as the initial owner.
     */
    function __Ownable_init_unchained(address _management) internal initializer {
        require( _management != address(0),"management address cannot be 0");
        _owner = _management;
        emit OwnershipTransferred(address(0), _management);
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

contract Crosschain  is Initializable,Ownable {
    using SafeMath for uint256;
    bool public pause;
    uint256 public nodeNum;
    uint256 public stakeNum;
    bytes32 public DOMAIN_SEPARATOR;
    bool public mainChainSta;
    mapping(string => mapping(address => uint256)) public chargeRate;
    mapping(address => uint256) public tokenSta;
    mapping(address => uint256) feeAmount;
    mapping(string => bool) public chainSta;
    mapping(string => mapping(string => bool)) status;
    mapping(address => uint256) nodeAddrIndex;
    mapping(uint256 => address) public nodeIndexAddr;
    mapping(address => bool) public nodeAddrSta;
    mapping(uint256 => Stake) public stakeMsg;
    event UpdatePause(bool sta);
    event WithdrawChargeAmount(address tokenAddr, uint256 amount);
    event AddNodeAddr(address[] nodeAddrs);
    event DeleteNodeAddr(address[] nodeAddrs);
    event UpdateChainCharge(string chain, bool sta, address[] tokens, uint256[] fees);
    event TransferToken(address indexed _tokenAddr, address _receiveAddr, uint256 _amount, string chain, string txid);
    event StakeToken(address indexed _tokenAddr, address indexed _userAddr, string receiveAddr, uint256 amount, uint256 fee,string chain);
   
    struct Data {
        address userAddr;
        address contractAddr;
        uint256 amount;
        uint256 expiration;
        string chain;
        string txid;
    }

    struct Stake {
        address tokenAddr;
        address userAddr;
        string receiveAddr;
        uint256 amount;
        uint256 fee;
        string chain;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    modifier onlyGuard() {
        require(!pause, "Crosschain: The system is suspended");
        _;
    }

    function init(
        address _management,
        bool _sta
    )  external initializer{
        __Ownable_init_unchained(_management);
        __Crosschain_init_unchained(_sta);
    }

    function __Crosschain_init_unchained(bool _sta) internal initializer{
        mainChainSta = _sta;
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

    function updatePause(bool _sta) external onlyOwner{
        pause = _sta;
        emit UpdatePause(_sta);
    }

    function updateChainCharge(
        string calldata _chain, 
        bool _sta, 
        address[] calldata _tokens, 
        uint256[] calldata _fees,
        uint256[] calldata _stas
    ) external onlyOwner
    {
        chainSta[_chain] = _sta;
        require(_tokens.length == _fees.length && _fees.length == _stas.length, "Parameter array length does not match");
        for (uint256 i = 0; i< _tokens.length; i++){
            chargeRate[_chain][_tokens[i]] = _fees[i];
            require(_stas[i] < 3, "Incorrect token state setting");
            tokenSta[_tokens[i]] = _stas[i];
        }
        emit UpdateChainCharge(_chain, _sta, _tokens, _fees);
    }

    function withdrawChargeAmount(address[] calldata tokenAddrs, address receiveAddr) external onlyOwner{
        require( receiveAddr != address(0),"receiveAddr address cannot be 0");
        for (uint256 i = 0; i< tokenAddrs.length; i++){
            uint256 _feeAmount = feeAmount[tokenAddrs[i]];
            if(tokenAddrs[i] == address(0x0)){
                require(address(this).balance >= _feeAmount, "Insufficient amount of balance");
                payable(receiveAddr).transfer(_feeAmount);
            }else{
                IERC20 token = IERC20(tokenAddrs[i]);
                token.transfer(receiveAddr,_feeAmount);
            }
            feeAmount[tokenAddrs[i]] = 0;
            emit WithdrawChargeAmount(tokenAddrs[i], _feeAmount);
        }
    }

    function addNodeAddr(address[] calldata _nodeAddrs) external onlyOwner{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(!nodeAddrSta[_nodeAddr], "This node is already a node address");
            nodeAddrSta[_nodeAddr] = true;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex == 0){
                _nodeAddrIndex = ++nodeNum;
                nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
            }
        }
        emit AddNodeAddr(_nodeAddrs);
    }

    function deleteNodeAddr(address[] calldata _nodeAddrs) external onlyOwner{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(nodeAddrSta[_nodeAddr], "This node is not a pledge node");
            nodeAddrSta[_nodeAddr] = false;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex > 0){
                uint256 _nodeNum = nodeNum;
                address _lastNodeAddr = nodeIndexAddr[_nodeNum];
                nodeAddrIndex[_lastNodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _lastNodeAddr;
                nodeAddrIndex[_nodeAddr] = 0;
                nodeIndexAddr[_nodeNum] = address(0x0);
                nodeNum--;
            }
        }
        emit DeleteNodeAddr(_nodeAddrs);
    }

    function stakeToken(string memory _chain, string memory receiveAddr, address tokenAddr, uint256 _amount) payable external {
        address _sender = msg.sender;
        require( chainSta[_chain], "Crosschain: The chain does not support transfer");
        uint256 _sta = tokenSta[tokenAddr];
        IERC20 token = IERC20(tokenAddr);
        if(mainChainSta){
            _amount = msg.value;
            require(_amount > 0, "Value must be greater than 0");
        }else {
            require(msg.value == 0, "Value must be equal to 0");
            require(_sta > 0, "Incorrect token state setting");
            require(token.transferFrom(_sender,address(this),_amount), "Token transfer failed");
        }
        uint256 _fee = chargeRate[_chain][tokenAddr];
        _amount = _amount.sub(_fee);
        feeAmount[tokenAddr] = feeAmount[tokenAddr].add(_fee);
        stakeMsg[++stakeNum] = Stake(tokenAddr, _sender, receiveAddr, _amount, _fee, _chain);
        if(!mainChainSta && _sta == 2){
            require(token.burn(_amount), "Token burn failed");
        }
        emit StakeToken(tokenAddr, _sender, receiveAddr, _amount, _fee, _chain);
    }

    /**
    * @notice A method in which issue transfer tokens to users. 
    * @param addrs [User address, token contract address]
    * @param uints [Number of luca fragments (0 for non-luca tokens), number of transfers, expiration time]
    * @param strs [chain name, transaction id]
    * @param vs  array of signature data
    * @param rssMetadata array of signature data
    */
    function transferToken(
        address[2] calldata addrs,
        uint256[2] calldata uints,
        string[] calldata strs,
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata
    )
        external
        onlyGuard
    {
        require( block.timestamp<= uints[1], "Crosschain: The transaction exceeded the time limit");
        require( !status[strs[0]][strs[1]], "Crosschain: The transaction has been withdrawn");
        status[strs[0]][strs[1]] = true;
        uint256 len = vs.length;
        uint256 counter;
        require(len*2 == rssMetadata.length, "Crosschain: Signature parameter length mismatch");
        bytes32 digest = getDigest(Data( addrs[0], addrs[1], uints[0], uints[1], strs[0], strs[1]));
        for (uint256 i = 0; i < len; i++) {
            bool result = verifySign(
                digest,
                Sig(vs[i], rssMetadata[i*2], rssMetadata[i*2+1])
            );
            if (result){
                counter++;
            }
        }
        require(
            counter > nodeNum/2,
            "The number of signed accounts did not reach the minimum threshold"
        );
        _transferToken(addrs, uints, strs);
    }
   
    function queryCharge(address[] calldata addrs) external view returns (address[] memory, uint256[] memory) {
        address[] memory _addrArray = new address[](1) ;
        uint256[] memory _chargeAmount = new uint256[](1) ;
        uint256 len = addrs.length;
        _addrArray = new address[](len) ;
        _chargeAmount = new uint256[](len) ;
        for (uint256 i = 0; i < len; i++) {
            _addrArray[i] = addrs[i];
            _chargeAmount[i] = feeAmount[addrs[i]];
        }
        return (_addrArray, _chargeAmount);
    }
        
    function queryNode() external view returns (address[] memory) {
        address[] memory _addrArray = new address[](nodeNum) ;
        uint j;
        for (uint256 i = 1; i <= nodeNum; i++) {
            address _nodeAddr = nodeIndexAddr[i];
            _addrArray[j] = _nodeAddr;
            j++;
        }
        return (_addrArray);
    }
    
    function _transferToken(address[2] memory addrs, uint256[2] memory uints, string[] memory strs) internal {
        if(mainChainSta){
            require(address(this).balance >= uints[0], "Insufficient amount of balance");
            payable(addrs[0]).transfer(uints[0]);
        }else {
            require( tokenSta[addrs[1]] >0 , "Crosschain: The token does not support transfers");
            IERC20 token = IERC20(addrs[1]);
            if(tokenSta[addrs[1]] == 1){
                require(token.transfer(addrs[0], uints[0]), "Token transfer failed");
            }else{
                require(token.mint(addrs[0], uints[0]), "Token transfer failed");
            }
            
        }
        emit TransferToken(addrs[0], addrs[1], uints[0], strs[0], strs[1]);
    }

    function verifySign(bytes32 _digest,Sig memory _sig) internal view returns (bool)  {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(prefix, _digest));
        address _nodeAddr = ecrecover(hash, _sig.v, _sig.r, _sig.s);
        require(_nodeAddr !=address(0),"Illegal signature");
        return nodeAddrSta[_nodeAddr];
    }
    
    function getDigest(Data memory _data) internal view returns(bytes32 digest){
        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(_data.userAddr, _data.contractAddr,  _data.amount, _data.expiration, _data.chain, _data.txid))
            )
        );
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