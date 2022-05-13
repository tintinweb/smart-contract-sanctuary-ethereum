/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC1155Metadata is IERC1155 {
    function uri(uint256 _id) external view returns (string memory);
}

interface IERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external returns(bytes4);
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external returns(bytes4);       
}

interface IERC20 {
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}

interface IProxyRegistry{
    function proxies(address) external view returns(address);
}

contract LustNFT {
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    struct Minter{
        address token;
        uint256 amountPerShare;
        bool redeemEnable;
    }
    struct Total{
        uint256 totalDonors;
        uint256 totalDonateAmount;
        uint256 totalRedeemed;
        uint256 totalDonations;
    }
    mapping(uint256 => uint256) public totalSupply;
    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => bool) public defaultApproved;
    string private _uri;
    string public name;
    string public symbol;
    bool private _lock;
    address payable public recipient = payable(0x5881Be40EC3044edD9512B56c3cC71003c4080f2);
    Minter[] public minters;
    uint256 private denominator = 50;
    uint256 private startTime;
    uint256 private duration = 7 days;
    mapping(uint256 => Total) public totalInfo;
    bool public paused;
    address public owner;
    mapping(address => mapping(uint256 => uint256)) private donatedAmount;
    uint256 public cap = 133785730;
    address public registry = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    
    modifier lock() {
        require(!_lock, "locked");
        _lock = true;
        _;
        _lock = false;
    }
    
    modifier notPaused() {
        require(!paused, "paused");
        _;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner");
        _;
    }
    
    modifier checkId(uint256 tokenId) {
        require(tokenId < minters.length, "tokenId not allowed");
        _;
    }
    
    constructor(uint256 _startTime, string memory _name, string memory _symbol, string memory uri_) {
        _uri = uri_;
        name = _name;
        symbol = _symbol;
        startTime = _startTime;
        owner = msg.sender;
        defaultApproved[address(this)] = true;
        _mint(recipient, 0, 100, "");
        _mint(recipient, 1, 300, "");
        _mint(recipient, 2, 600, "");
        minters.push(Minter(address(0), 1e17, false));
        minters.push(Minter(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD, 1e21, false));
        minters.push(Minter(0xbd31EA8212119f94A611FA969881CBa3EA06Fa3d, 1e12, false));
    }
    
    function exists(uint256 id) public view returns (bool) {
        return totalSupply[id] > 0;
    }
    
    function uri(uint256 id) public view returns(string memory){
        return bytes(_uri).length == 0 ? "" : string(abi.encodePacked(_uri, toString(id)));
    }
    
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view returns (uint256[] memory) {
        require(accounts.length == ids.length);
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf[accounts[i]][ids[i]];
        }
        return batchBalances;
    }
    
    function setApprovalForAll(address operator, bool approved) public {
        address _caller = msg.sender;
        require(_caller != operator);
        _operatorApprovals[_caller][operator] = approved;
        emit ApprovalForAll(_caller, operator, approved);
    }
    
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        if(defaultApproved[operator]) return true;
        if(IProxyRegistry(registry).proxies(account) == operator) return true;
        return _operatorApprovals[account][operator];
    }
    
    function supportsInterface(bytes4 interfaceID) external pure returns (bool){
        return interfaceID == type(IERC165).interfaceId || 
        interfaceID == type(IERC1155).interfaceId || 
        interfaceID == type(IERC1155Metadata).interfaceId;
    }
    
    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, 
        uint256 id, uint256 amount, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                require(response == IERC1155Receiver.onERC1155Received.selector);
            } catch {
                revert();
            }
        }
    }
    
    function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, 
        uint256[] memory amounts, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                require(response == IERC1155Receiver.onERC1155BatchReceived.selector);
            } catch {
                revert();
            }
        }
    }
    
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public {
        address operator = msg.sender;
        require(from == operator || isApprovedForAll(from, operator));
        require(to != address(0));
        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;
        emit TransferSingle(operator, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }
    
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, 
        uint256[] memory amounts, bytes memory data) public {
        address operator = msg.sender;
        require(from == operator || isApprovedForAll(from, operator));
        require(ids.length == amounts.length);
        require(to != address(0));
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;
        }
        emit TransferBatch(operator, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }
    
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
        require(to != address(0));
        address operator = msg.sender;
        balanceOf[to][id] += amount;
        totalSupply[id] += amount;
        require(totalSupplyOfAll() <= cap, "over cap");
        emit TransferSingle(operator, address(0), to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }
    
    function mint(uint256 tokenId, uint256 share) public payable checkId(tokenId) notPaused lock{
        require(block.timestamp >= startTime, "not open");
        require(block.timestamp <= startTime + duration, "already end");
        require(share >= 1, "Zero share");
        Minter memory minter = minters[tokenId];
        address _caller = msg.sender;
        uint256 donateAmount = share * minter.amountPerShare;
        uint256 fee = minter.amountPerShare / denominator * share;
        uint256 value = msg.value;
        address token = minter.token;
        if(token == address(0)){
            require(value >= donateAmount,"not enough eth");
            recipient.transfer(donateAmount);
            value -= donateAmount;
        }else{
            IERC20(token).transferFrom(_caller, address(this), donateAmount);
            IERC20(token).transfer(recipient, fee);
        }
        _mint(_caller, tokenId, share, "");
        Total storage total = totalInfo[tokenId];
        total.totalDonateAmount += donateAmount;
        total.totalDonations++;
        if (donatedAmount[_caller][tokenId] == 0) {
            total.totalDonors++;
        }
        donatedAmount[_caller][tokenId] += share;
        if(value > 0){
            payable(_caller).transfer(value);
        }
    }
    
    function redeem(uint256 tokenId, uint256 share) public checkId(tokenId) notPaused lock {
        require(share >= 1, "Zero share");
        address _caller = msg.sender;
        Minter memory minter = minters[tokenId];
        require(minter.redeemEnable, "not allowed redeem");
        address token = minter.token;
        Total storage total = totalInfo[tokenId];
        uint256 redeemAmount = share * minter.amountPerShare;
        require(total.totalRedeemed + redeemAmount <= total.totalDonateAmount, "not enough token");
        uint256 fee = minter.amountPerShare / denominator * share;
        safeTransferFrom(_caller, address(this), tokenId, share, "");
        IERC20(token).transfer(_caller, redeemAmount - fee);
        total.totalRedeemed += redeemAmount;
    }
    
    function getDonateInfo() public view returns(
            address _recipient,
            uint256 _feePerShare,
            uint256 _denominator,
            uint256 _startTime,
            uint256 _duration,
            Minter[] memory _minters,
            Total[] memory _totalInfos
    ) {
        uint256 len = minters.length;
        Total[] memory totalInfos = new Total[](minters.length);
        for(uint256 i = 0; i < len; i++){
            totalInfos[i] = totalInfo[i];
        }
        return(
            recipient,
            2,
            100,
            startTime,
            duration,
            minters,
            totalInfos
        );
    }
    
    function getUserInfo(address user) external view returns(uint256[] memory _donatedAmounts){
        uint256 len = minters.length;
        _donatedAmounts = new uint256[](len);
        for(uint256 i = 0; i < len; i++){
            _donatedAmounts[i] = donatedAmount[user][i];
        }
    }
    
    function totalSupplyOfAll() public view returns (uint256){
        uint256 sum = 0;
        for(uint256 i = 0; i < minters.length; i++){
            sum += totalSupply[i];
        }
        return sum;
    }
    
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external returns(bytes4){
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external returns(bytes4){
        return this.onERC1155BatchReceived.selector;
    }
    
    function addMinter(address token, uint256 amountPerShare) public onlyOwner{
        minters.push(Minter(token, amountPerShare, false));
    }
    
    function setMinter(uint256 tokenId, bool enable) public checkId(tokenId) onlyOwner{
        require(tokenId > 0, "set eth");
        minters[tokenId].redeemEnable = enable;
    }
    
    function setStartTime(uint256 _startTime) public onlyOwner{
        startTime = _startTime;
    }
     
    function setDuration(uint256 _duration) public onlyOwner{
        duration = _duration;
    }
    
    function setPaused(bool _paused) public onlyOwner{
        paused = _paused;
    }
    
    function setOwner(address _owner) public onlyOwner{
        owner = _owner;
    }

    function setDefaultApproved(address _account, bool enable) public onlyOwner{
        defaultApproved[_account] = enable;
    }
    
    function setRegistry(address _registry) public onlyOwner{
        registry = _registry;
    }
    
    function setURI(string memory uri_) public onlyOwner{
        _uri = uri_;
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
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
}