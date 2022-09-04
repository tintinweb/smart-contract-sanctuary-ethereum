// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DNARegister.sol";
import "./DNAToken.sol";

contract CommitAndRevealContract is Ownable{
    using SafeMath for uint256;

    mapping(bytes32=>address) public commits;
    mapping(bytes32 => uint) public commitRevealTimeOut;

    uint public COMMITMENT_TIME_OUT = 60*60;
    uint public MIN_WAIT_TIME = 3*60;

    function updateCRCConstants(uint _minWaitTime, uint _commitmentTimeout) external onlyOwner{
        COMMITMENT_TIME_OUT = _commitmentTimeout;
        MIN_WAIT_TIME = _minWaitTime;
    }

    function commitDName(bytes32 _dnaHash) public {
        require( (commits[_dnaHash] == address(0)) ||
            (commits[_dnaHash] != address(0) && block.timestamp > commitRevealTimeOut[_dnaHash].add(COMMITMENT_TIME_OUT))
        , "Hash already commited, try different salt!");
        commits[_dnaHash] = msg.sender;
        commitRevealTimeOut[_dnaHash] = block.timestamp;
    }

    function revealDName(string calldata _dnaname, uint _dnaId, string memory _tld, uint _durationInYrs,
        string calldata _commitSalt, address _msgSender) internal returns(bool){
        bytes32 _dnaHash = keccak256(abi.encodePacked(_dnaname, _dnaId, _tld, _durationInYrs, _commitSalt, _msgSender));
        require(commits[_dnaHash] == msg.sender, "You did not commited this hash!");
        require(block.timestamp >= commitRevealTimeOut[_dnaHash].add(MIN_WAIT_TIME),
            "You must wait minimum wait time before revealing the hash!");
        require(block.timestamp < commitRevealTimeOut[_dnaHash].add(COMMITMENT_TIME_OUT),
            "Commit Expired, more than 60 min lapsed!");
        commits[_dnaHash] = address(0);
        commitRevealTimeOut[_dnaHash] = 0;
        return true;
    }

    //TODO Remove this hash function
    function hash(string calldata _dnaname, bytes32 _dnaId, string memory _tld, uint _durationInYrs,
        string calldata _commitSalt) external returns (bytes32) {
        return keccak256(abi.encodePacked(_dnaname, _dnaId, _tld, _durationInYrs, _commitSalt, msg.sender));
    }
}

contract DNameCredit is Ownable{
    using SafeMath for uint256;
    mapping(address=>mapping(string => Credit)) public credits;

    struct Credit{
        uint noOfYears;
        uint noOfChars;
        uint ttl;
    }

    function assignDNameCredit(address _receiver, string calldata _tld, uint _noOfChars,
        uint _noOfYears, uint _expiryInDays) onlyOwner external {
        Credit memory _cred;
        _cred.noOfChars = _noOfChars;
        _cred.noOfYears = _noOfYears;
        _cred.ttl = block.timestamp.add(_expiryInDays.mul(24).mul(60).mul(60));
        credits[_receiver][_tld] = _cred;
    }

    function getDNameCreditYearsAndConsume(string memory _tld, uint _noOfChars)
    internal returns(uint){
        if(credits[msg.sender][_tld].noOfChars == _noOfChars &&
            block.timestamp < credits[msg.sender][_tld].ttl){
            uint noOfYears = credits[msg.sender][_tld].noOfYears;
            credits[msg.sender][_tld].noOfChars = 0;
            credits[msg.sender][_tld].noOfYears = 0;
            credits[msg.sender][_tld].ttl = 0;
            return noOfYears;
        }
        return 0;
    }
}

contract DNameAssociatedData is SLDRegister{
    using SafeMath for uint256;

    // keys : subdomain_1, subdomain_2 ..., (addr_coinId_index) addr_0_0, add_60_1, ...., ipfs_0 ipfs_1... MX_Record.... twitter.com gmail.com facebook.com....
    mapping (uint => mapping(string => string)) public idsToDNameData;

    mapping (uint => string[]) public keysForId;
    mapping (string => uint) public anyTypeAddressToId;
    /*
     addNewKVPair(_dnaId, "subdomain_0", "subdomain1", true);
    addNewKVPair(_domId, "ipfs_0", "QmPHVjLmcSj3v5U4r7mk87sMv5zwUP2zhJ9RAdfvZnam6X", true);
    addNewKVPair(_domId, "address_0_0", "bc1q4cyrfeck2ffuXud3rT5l5aYyv6f0chkp0zpemf", true);
    addNewKVPair(_domId, "twitter_com_0", "@deflationx", true);
    addNewKVPair(_domId, "facebook_com_0", "[email protected]", true);
    addNewKVPair(_domId, "gmail_com_0", "[email protected]", true);
    addNewKVPair(_domId, "proton_me_0", "[email protected]", true);
    addNewKVPair(_domId, "call_me_0", "+123456789101112", true);
    addNewKVPair(_dnaId, "whats_app_0", "+123456789101112", true); */

    function getAddressForDomName(string calldata _dname, string calldata _key) external view returns(string memory){
        uint _dnaId = Utils.getDomNameHashFromName(_dname);
        return idsToDNameData[_dnaId][_key];
    }

    function getDomNameFromAddress(string calldata _addr) external view returns(string memory _dname){
        uint _dnaId = anyTypeAddressToId[_addr];
        return sldRegister[_dnaId].dname;
    }

    function _deleteKeyFromKeyArray(uint _dnaId, string memory _key) private {
        bytes32 _keyHash = keccak256(abi.encodePacked(_key));
        for(uint _ind = 0; _ind < keysForId[_dnaId].length; _ind++ )
            if( keccak256(abi.encodePacked(keysForId[_dnaId][_ind])) == _keyHash)
                delete keysForId[_dnaId][_ind];
    }

    function getAllKeys(uint _dnaId) external view returns(string[] memory){
        return keysForId[_dnaId];
    }

    function addNewKVPair(uint256 _dnaId, string memory _key, string memory _value, bool isAddress) public onlySldController(_dnaId) {
        _addNewKVPair( _dnaId, _key, _value, isAddress);
    }

    function _addNewKVPair(uint256 _dnaId, string memory _key, string memory _value, bool isAddress) private {
        idsToDNameData[_dnaId][_key] = _value;
        keysForId[_dnaId].push(_key);

        if(isAddress){
            anyTypeAddressToId[_value] = _dnaId;
        }
    }

    function updateKVPair(uint256 _dnaId, string memory _key, string memory _value, bool isAddress) public onlySldController(_dnaId) {
        string memory oldValue = idsToDNameData[_dnaId][_key];
        idsToDNameData[_dnaId][_key] = _value;
        if(isAddress){
            anyTypeAddressToId[oldValue] = 0;
            anyTypeAddressToId[_value] = _dnaId;
        }
    }

    function deleteKVPair(uint256 _dnaId, string memory _key, bool isAddress) public onlySldController(_dnaId) {
        _deleteKVPair(_dnaId, _key, isAddress);
    }

    function _deleteKVPair(uint256 _dnaId, string memory _key, bool isAddress) private{
        string memory _value = idsToDNameData[_dnaId][_key];
        idsToDNameData[_dnaId][_key] = "";
        _deleteKeyFromKeyArray(_dnaId, _key);

        if(isAddress){
            anyTypeAddressToId[_value] = 0;
        }
    }

    function setMultipleKVPairs(uint256 _dnaId, string[] calldata _keys, string[] calldata _values, bool[] memory isValueAddress)
    external onlySldController(_dnaId) {
        for(uint i=0; i < _keys.length; i++){
            _addNewKVPair( _dnaId, _keys[i], _values[i], isValueAddress[i]);
        }
    }
    //TODO test this function
    function deleteMultipleKVPairs(uint256 _dnaId, string[] calldata _keys, bool[] memory isValueAddress) external onlySldController(_dnaId) {
        for(uint i=0; i < _keys.length; i++){
            _deleteKVPair(_dnaId, _keys[i], isValueAddress[i]);
        }
    }
}

contract DNANFT is ERC721, CommitAndRevealContract, DNameCredit, DNameAssociatedData {
    using SafeMath for uint256;

    // Real Owner must renew within 15 days of expiration
    uint public GRACE_PERIOD_REAL_OWNER = uint(15).mul(24).mul(60).mul(60);

    // Anyone can release and then acquire dna after 30 days of expiration
    uint public GRACE_PERIOD_ANYONE = uint(30).mul(24).mul(60).mul(60);

    uint256 public dnasNFTCounter = 0;
    DNAToken public dnaToken;

    receive() external payable{}

    event NAME_REGISTERED(string _dnaname, string _tld, uint _dnaId, address _sldController, uint _ttl, string referralCode);
    event NAME_TRANSFERRED(address _msgSender, address newOwner, uint _dnaId);
    event NAME_EXTENDED(uint _dnaId, uint _noOfYears, uint _updatedTtl, address extendedBy);
    event ERC20_TOKEN_TRANSFERRED(address msgSender, address to, uint amount);

    constructor(address payable dnaTokenContractAddr) ERC721("Decenteralized NAme NFT", "DNA") {
        dnaToken = DNAToken(dnaTokenContractAddr);
    }

    function updateNameNftConstants(uint _gracePeriodRealOwner, uint _gracePeriodAnyone) external onlyOwner {
        GRACE_PERIOD_REAL_OWNER = _gracePeriodRealOwner;
        GRACE_PERIOD_ANYONE = _gracePeriodAnyone;
    }

    function setDomTokenContractAddr(address payable dnaTokenContractAddr) external onlyOwner{
        dnaToken = DNAToken(dnaTokenContractAddr);
    }

    function withdraw(address _to, uint amount) external onlyOwner {
        (bool success, ) = _to.call{value: amount}("");
        require(success ," Sent failure " );
    }

    function transferERC20(IERC20 token, address to, uint256 amount) external onlyOwner {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to, amount);
        emit ERC20_TOKEN_TRANSFERRED(msg.sender, to, amount);
    }

    function _createDomEntry(uint _dnaId, string calldata _dnaname, string memory _tld,
        address _sldController, uint _durationInYrs, string memory referralCode) private {
        _safeMint(msg.sender, _dnaId);

        uint _ttl = block.timestamp.add(_durationInYrs.mul(365).mul(24).mul(60).mul(60));
        _addSLD(_dnaId, _tld, _dnaname, _sldController, _ttl);
        addNewKVPair(_dnaId, "address_60_0", Utils.toHexString(msg.sender), true);
        /*
            addNewKVPair(_dnaId, "subdomain_0", "subdomain1", true);
            addNewKVPair(_dnaId, "ipfs_0", "QmPHVjLmcSj3v5U4r7mk87sMv5zwUP2zhJ9RAdfvZnam6X", true);
            addNewKVPair(_dnaId, "address_0_0", "bc1q4cyrfeck2ffuXud3rT5l5aYyv6f0chkp0zpemf", true);
            addNewKVPair(_dnaId, "twitter_com_0", "@deflationx", true);
    addNewKVPair(_dnaId, "facebook_com_0", "[email protected]", true);
    addNewKVPair(_dnaId, "gmail_com_0", "[email protected]", true);
    addNewKVPair(_dnaId, "proton_me_0", "[email protected]", true);
    addNewKVPair(_dnaId, "call_me_0", "+123456789101112", true);
    addNewKVPair(_dnaId, "whats_app_0", "+123456789101112", true);
*/
        dnasNFTCounter++;
        emit NAME_REGISTERED(_dnaname, _tld, _dnaId, _sldController, _ttl, referralCode);
    }

    function _mintDName(string memory _tld, string calldata _dnaname, address _sldController,
        uint _durationInYrs) private {
        require(topLDControllers[_tld] != address(0), "TLD doesnt exist!");

        uint256 _dnaId = Utils.getDomNameHashFromName(_dnaname);
        _createDomEntry(_dnaId, _dnaname, _tld, _sldController, _durationInYrs, '');
    }

    function mintByOwner(string calldata _dnaname, string memory _tld, uint _durationInYrs) external onlyOwner{
        require(!sldRegistered(_dnaname), "DName Already Registered!");
        _mintDName(_tld, _dnaname, msg.sender, _durationInYrs);
    }

    function mintForCredit(string calldata _dnaname, string calldata _commitSalt) external {
        require(!sldRegistered(_dnaname), "DName Already Registered!");
        uint256 _dnaId = Utils.getDomNameHashFromName(_dnaname);
        string memory _tld = Utils.extractTLD(_dnaname);
        uint _dnameChars = Utils.getUTFCharsLenInName(_dnaname, bytes(_tld).length);
        uint _durationInYrs = getDNameCreditYearsAndConsume(_tld, _dnameChars);
        require(_durationInYrs > 0, "In valid duration!");

        require(revealDName(_dnaname, _dnaId, _tld, _durationInYrs, _commitSalt, msg.sender), " No Commit Found For DName!");

        _mintDName(_tld, _dnaname, msg.sender, _durationInYrs);
    }

    function mint(string calldata _dnaname, string calldata _commitSalt, uint _durationInYrs,
        string memory referralCode) external payable{
        require(!sldRegistered(_dnaname), "DName Already Registered!");
        uint256 _dnaId = Utils.getDomNameHashFromName(_dnaname);
        string memory _tld = Utils.extractTLD(_dnaname);
        require(revealDName(_dnaname, _dnaId, _tld, _durationInYrs, _commitSalt, msg.sender), " No Commit Found For DName!");
        require(topLDControllers[_tld] != address(0), "TLD doesnt exist!");

        uint dnameChars = Utils.getUTFCharsLenInName(_dnaname, bytes(_tld).length);
        bool success;
        if(msg.value > 0){
            success = dnaToken.registerOrExtendDnameWithEth{value:msg.value}
            (dnameChars, _tld,_durationInYrs,false,msg.sender);
        }else{
            success = dnaToken.registerOrExtendDnameWithDNA(dnameChars, _tld,_durationInYrs,false,msg.sender);
        }
        require(success, "Transfer of funds failed!");
        _createDomEntry(_dnaId, _dnaname, _tld, msg.sender, _durationInYrs, referralCode);
    }

    function safeTransferFrom(address _from, address _to, uint _dnaId, bytes memory _data) public override{
        require(_isApprovedOrOwner(_msgSender(), _dnaId), "Only Owner can transfer NFT DName");
        _transferDNameWithDNA(_dnaId, _to);
        _safeTransfer(_from, _to, _dnaId, _data);
        emit NAME_TRANSFERRED( _from, _to, _dnaId);
    }

    function safeTransferFrom(address _from, address _to, uint _dnaId) public override{
        safeTransferFrom(_from, _to, _dnaId, '');
    }

    function transferFrom(address _from, address _to, uint _dnaId) public override {
        require(_isApprovedOrOwner(_msgSender(), _dnaId), "Only NFT Owner can transfer NFT DName");
        _transferDNameWithDNA(_dnaId, _to);
        _transfer(_from, _to, _dnaId);
        emit NAME_TRANSFERRED( _from, _to, _dnaId);
    }

    function _transferDNameWithDNA(uint _dnaId, address newOwner) private onlySldOwner(_dnaId) {
        bool success = false;
        uint _dnameCharLen = Utils.getUTFCharsLenInName(sldRegister[_dnaId].dname, bytes(sldRegister[_dnaId].tld).length);
        success = dnaToken.registerOrExtendDnameWithDNA(_dnameCharLen, sldRegister[_dnaId].tld,1,true,msg.sender);
        require(success, "Payment failed!");

        _updateSLD(_dnaId, newOwner, newOwner, block.timestamp.add(GRACE_PERIOD_REAL_OWNER));
    }

    function transferDNameWithEth(uint _dnaId, address newOwner, uint _noOfYears) external payable onlySldOwner(_dnaId) {
        bool success = false;
        uint _dnameCharLen = Utils.getUTFCharsLenInName(sldRegister[_dnaId].dname, bytes(sldRegister[_dnaId].tld).length);
        success = dnaToken.registerOrExtendDnameWithEth{value:msg.value}(_dnameCharLen, sldRegister[_dnaId].tld,_noOfYears+1,true,msg.sender);
        require(success, "Payment failed!");

        uint _newTtl = block.timestamp.add(_noOfYears.mul(365).mul(24).mul(60).mul(60));
        _updateSLD(_dnaId, newOwner, newOwner, _newTtl);

        _transfer(msg.sender, newOwner, _dnaId);
        emit NAME_TRANSFERRED( msg.sender, newOwner, _dnaId);
    }

    function extendDNamePeriodByOwner(uint _dnaId, uint _noOfYears) onlyOwner external {
        _extendDNamePeriod( _dnaId, _noOfYears);
    }

    function _extendDNamePeriod(uint _dnaId, uint _noOfYears) private {
        uint expiryTimeWithGracePeriod = sldRegister[_dnaId].ttl.add(GRACE_PERIOD_REAL_OWNER);

        if(expiryTimeWithGracePeriod >= block.timestamp){
            uint extensionInSeconds = _noOfYears.mul(365).mul(24).mul(60).mul(60);
            sldRegister[_dnaId].ttl = sldRegister[_dnaId].ttl.add(extensionInSeconds);
            emit NAME_EXTENDED(_dnaId, _noOfYears, sldRegister[_dnaId].ttl, msg.sender);
        }else{
            _transfer(sldRegister[_dnaId].sldOwner, topLDControllers[sldRegister[_dnaId].tld], _dnaId);
            _moveExpiredDNameToTLDController(_dnaId);
        }
    }

    function extendDNamePeriod(uint _dnaId, uint _noOfYears) external payable{
        bool success = false;
        uint _dnameCharLen = Utils.getUTFCharsLenInName(sldRegister[_dnaId].dname, bytes(sldRegister[_dnaId].tld).length);
        if(msg.value > 0){
            success = dnaToken.registerOrExtendDnameWithEth{value:msg.value}
            (_dnameCharLen, sldRegister[_dnaId].tld,_noOfYears,false,msg.sender);
        }else{
            success = dnaToken.registerOrExtendDnameWithDNA(_dnameCharLen, sldRegister[_dnaId].tld,_noOfYears,false,msg.sender);
        }
        require(success, "Payment failed!");
        _extendDNamePeriod( _dnaId, _noOfYears);
    }

    function claimExpiredDNameNFT(uint _dnaId) external onlyOwner{
        uint expiryTimeWithGracePeriod = sldRegister[_dnaId].ttl.add(GRACE_PERIOD_REAL_OWNER);
        require(expiryTimeWithGracePeriod < block.timestamp, "Name not yet expired with grace period!");
        _transfer(sldRegister[_dnaId].sldOwner, topLDControllers[sldRegister[_dnaId].tld], _dnaId);
        _moveExpiredDNameToTLDController(_dnaId);
    }

    function claimAndReleaseExpiredDNameNFT(uint _dnaId) external payable{
        bool success = dnaToken.chargeDnameReleaseFeeFromEthValue{value:msg.value}(msg.sender);
        require(success, "Fee deduction failed!");
        uint expiryTimeWithGracePeriod = sldRegister[_dnaId].ttl.add(GRACE_PERIOD_ANYONE);
        require(expiryTimeWithGracePeriod < block.timestamp, "Name not expired with grace period!");
        _burn(_dnaId);
        _releaseExpiredDName(_dnaId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DNARegister.sol";

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20, Pausable {
    using SafeMath for uint256;

    uint256 public totalSupply;
    uint256 public treasuryTokens;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Burn(address indexed burner, uint256 value);

    enum FEE_TYPES {DNAME_TRANSFER_FEE, TOKEN_TRANSFER_FEE, TOKEN_BURN_FEE, TOKEN_BURN_RATE, DNAME_RELEASE_FEE_IN_USD}

    uint8[] public _dnaAndTokenFees = [25, 5, 10, 10, 25];

    function _setDnameFeesPercentages(uint8[] calldata _newDomFeesPercentages) onlyOwner whenNotPaused external {
        _dnaAndTokenFees = _newDomFeesPercentages;
    }

    function _getFeePercentageAmount(FEE_TYPES feeType, uint _amount) internal view returns(uint){
        return _amount.mul(_dnaAndTokenFees[uint(feeType)]).div(100);
    }

    function _chargeFeeAndBurn(address _from, uint _fee) internal {
        require(balanceOf[_from] >= _fee, "Insufficient token balance!");
        balanceOf[_from] = balanceOf[_from].sub(_fee);

        uint burnAmount = _getFeePercentageAmount(FEE_TYPES.TOKEN_BURN_RATE, _fee);
        if(burnAmount > 0){
            balanceOf[address(0)] = balanceOf[address(0)].add(burnAmount);
            totalSupply = totalSupply.sub(burnAmount);
            emit Burn(_from, burnAmount);
            emit Transfer(_from, address(0), burnAmount);
        }

        uint remainingFee = _fee.sub(burnAmount);
        balanceOf[owner()] = balanceOf[owner()].add(remainingFee);
        treasuryTokens = treasuryTokens.add(remainingFee);
        emit Transfer(_from, owner(), remainingFee);
    }

    function chargeFeeAndBurn(uint _fee) external whenNotPaused {
        _chargeFeeAndBurn(msg.sender, _fee);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        balanceOf[_from] = balanceOf[_from].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

    function transfer(address _to, uint256 _amount) external whenNotPaused returns (bool) {
        require(_to != address(0));
        uint _transferFee = _getFeePercentageAmount(FEE_TYPES.TOKEN_TRANSFER_FEE, _amount);
        require( _amount.add(_transferFee) <= balanceOf[msg.sender], "Insufficient balance, may be transfer fee is missing." );

        _transfer(msg.sender, _to, _amount);

        _chargeFeeAndBurn(msg.sender, _transferFee);
        return true;
    }

    function approve(address _spender, uint256 _amount) external whenNotPaused returns (bool) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) external whenNotPaused returns (bool) {
        require(_to != address(0));
        uint _transferFee = _getFeePercentageAmount(FEE_TYPES.TOKEN_TRANSFER_FEE,_amount);
        require( (_amount.add(_transferFee)) <= balanceOf[_from]);
        require( (_amount.add(_transferFee)) <= allowance[_from][msg.sender]);

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_amount.add(_transferFee));
        balanceOf[_from] = balanceOf[_from].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);
        emit Transfer(_from, _to, _amount);

        _chargeFeeAndBurn(_from, _transferFee);
        return true;
    }

    function increaseAllowance(address _spender, uint _incresedAmount) external whenNotPaused returns (bool) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_incresedAmount);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseAllowance(address _spender, uint _reducedAmount) external whenNotPaused returns (bool) {
        uint oldValue = allowance[msg.sender][_spender];
        if (_reducedAmount > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_reducedAmount);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
}

contract DNAToken is ERC20 {
    using SafeMath for uint256;

    string public name = "Web3 Names";
    string public symbol = "DNA";
    uint256 public decimals = 18;
    uint256 public maxSupply = uint(109_876_543_210).mul(10 ** decimals);
    bool public directMintAllowed = true;
    address public nameNFTContractAddr;
    PriceOracle public po;
    uint256[] public discountLevels = [1000, 5000, 10000, 25000, 50000, 100000, 500000, 1000000,
    5000000, 10000000, 25000000];

    uint8[] public discountLevelsPercentages = [0, 5, 10, 15, 20, 25, 30, 35, 40, 43, 47, 50];
    mapping(string => uint[]) public feesInUSD;

    event Mint(address indexed from, address indexed to, uint256 value);
    event ERC20_TOKEN_TRANSFERRED(address msgSender, address to, uint amount);

    constructor(uint256 _initialSupply, AggregatorV3Interface ethUsdAggr, AggregatorV3Interface domUsdAggr) {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        po = new PriceOracle(ethUsdAggr, domUsdAggr); //TODO uncomment
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function updateDiscountLevels(uint[] calldata _newDiscountLevels, uint8[] calldata _newDiscountLevelPercentages) external onlyOwner{
        discountLevels = _newDiscountLevels;
        discountLevelsPercentages = _newDiscountLevelPercentages;
    }

    function setFees(string calldata _tld, uint[] calldata _fees) external onlyOwner{
        feesInUSD[_tld] = _fees; // for 10 and 10+ characters
    }

    function setLongDnameNameFees(string calldata _tld, uint _fee_0) external onlyOwner{
        feesInUSD[_tld][0] = _fee_0; // for 10 and 10+ characters
    }

    function setNameNFTContractAddr(address nftContrAddr) external onlyOwner{
        nameNFTContractAddr = nftContrAddr;
    }

    function burn(uint256 _value) external {
        uint _burnFee = _getFeePercentageAmount(FEE_TYPES.TOKEN_BURN_FEE, _value);
        if(_burnFee >= _value){
            _burnFee = _value;
        }else{
            _burn(msg.sender, _value.sub(_burnFee));
        }
        _chargeFeeAndBurn(msg.sender, _burnFee);
    }

    function burnTreasury(uint256 _value) external onlyOwner{
        _burn(msg.sender, _value);
        treasuryTokens = treasuryTokens.sub(_value);
    }

    function _burn(address _who, uint256 _value) private {
        require(_value <= balanceOf[_who]);
        balanceOf[_who] = balanceOf[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function _mint(address account, uint256 amount) private {
        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) onlyOwner external {
        require(totalSupply.add(amount) <= maxSupply, " Max supply reached.");
        _mint(account, amount);
    }

    function _getDiscount(uint ethAmountReceived) private view returns(uint){
        uint ethUsd = 2000;//pO.getLatestPriceETHUSD(); // TODO Uncomment it

        uint ethRecievedInUSD = ethAmountReceived.mul(ethUsd).div(10**18);
        if(ethRecievedInUSD < discountLevels[0]){
            return discountLevelsPercentages[0];
        }else if(ethRecievedInUSD < discountLevels[1]){
            return discountLevelsPercentages[1];
        }else if(ethRecievedInUSD < discountLevels[2]){
            return discountLevelsPercentages[2];
        }else if(ethRecievedInUSD < discountLevels[3]){
            return discountLevelsPercentages[3];
        }else if(ethRecievedInUSD < discountLevels[4]){
            return discountLevelsPercentages[4];
        }else if(ethRecievedInUSD < discountLevels[5]){
            return discountLevelsPercentages[5];
        }else if(ethRecievedInUSD < discountLevels[6]){
            return discountLevelsPercentages[6];
        }else if(ethRecievedInUSD < discountLevels[7]){
            return discountLevelsPercentages[7];
        }else if(ethRecievedInUSD < discountLevels[8]){
            return discountLevelsPercentages[8];
        }else if(ethRecievedInUSD < discountLevels[9]){
            return discountLevelsPercentages[9];
        }else if(ethRecievedInUSD < discountLevels[10]){
            return discountLevelsPercentages[10];
        }else if(ethRecievedInUSD >= discountLevels[10]){
            return discountLevelsPercentages[11];
        }
        return 0;
    }

    function toggleDirectMint() external onlyOwner returns(bool){
        if(directMintAllowed){
            directMintAllowed = false;
        }else{
            directMintAllowed = true;
        }
        return directMintAllowed;
    }

    receive() external payable{}

    function withdraw(address _to, uint amount) onlyOwner external {
        (bool success, ) = _to.call{value: amount}("");
        require(success ," Sent failure " );
    }

    function transferERC20(IERC20 token, address to, uint256 amount) external onlyOwner {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to, amount);
        emit ERC20_TOKEN_TRANSFERRED(msg.sender, to, amount);
    }

    //dname will be expired after 15 days grace period and can be bought
    //index 0 for 10 or more chars first year fees, index 10 is after first year fee. index 11 is cutoff chars length (10 chars). index 12 is max discount no of years (50)
    //[0,5000,2500,1000,500,250,100,50,25,10,5,10,50]
    function calculateDnameFeeInDom(uint _dnaNameChars, string memory _tld, uint _durationInYears, bool _transferFee)
    public view returns(uint, uint ){
        uint _feeInDomWei;
        uint discountNoOfTokens = 0;
        uint domLengthCutoff = feesInUSD[_tld][11];

        uint domUsd = 1_000_000_000_000_000;//pO.getLatestPriceDNAUSD();// TODO Uncomment it

        if(_dnaNameChars >= domLengthCutoff){
            if(feesInUSD[_tld][0] != 0){
                _feeInDomWei = _durationInYears.mul(feesInUSD[_tld][0]);
            }else{
                _feeInDomWei = (_durationInYears-1).mul(feesInUSD[_tld][domLengthCutoff]);
            }
            if(_transferFee){
                _feeInDomWei = _durationInYears.mul(feesInUSD[_tld][domLengthCutoff]);
            }
            _feeInDomWei = _feeInDomWei.mul(10**18).mul(10**18).div(domUsd);
        }else{
            _feeInDomWei = _durationInYears.mul(feesInUSD[_tld][_dnaNameChars]);
            _feeInDomWei = _feeInDomWei.mul(10**18).mul(10**18).div(domUsd);

            //discountPercentages = [4, 5, 6, 7, 8, 9, ....]; +2% for every next year starting from year 2 at 4% 6% 8%...
            if(_durationInYears > 1 && _durationInYears <= feesInUSD[_tld][12] && _feeInDomWei > 0){
                discountNoOfTokens = _feeInDomWei.mul(_durationInYears.add(2)).div(100);
            }
        }
        return (_feeInDomWei, discountNoOfTokens);
    }

    function _mintOrBuyDNAFromOwner(uint _amountToMint, address _buyer) private {
        if(_amountToMint.add(totalSupply) <= maxSupply){
            _mint(_buyer, _amountToMint);
            return;
        }
        if(balanceOf[owner()] >= _amountToMint){
            _transfer(owner(), _buyer, _amountToMint);
            return;
        }
        revert("Not sufficient tokens to sell Or Mint!");
    }

    function mintOrBuyDNAForEth() external payable returns(bool){
        require(msg.value > 0, "Insufficient funds");
        require(directMintAllowed, "This feature is not allowed!");

        uint totalCoinsToMint = po.ethToDom(msg.value);
        uint discountPercentage = _getDiscount(msg.value);
        if(discountPercentage > 0 && discountPercentage <= 100 ){
            totalCoinsToMint = totalCoinsToMint.add(totalCoinsToMint.mul(discountPercentage).div(100));
        }
        _mintOrBuyDNAFromOwner(totalCoinsToMint, msg.sender);
        return true;
    }

    function _registerOrExtendDnameWithEth(uint _dnaNameChars, string calldata _tld,
        uint _durationInYears, address _buyer, uint ethAmount, bool _transfer) private returns(bool) {
        (uint feeInDom, uint discountNoOfTokens) = calculateDnameFeeInDom(_dnaNameChars, _tld, _durationInYears, _transfer);
        uint _domWeiTokenTotalForEth = po.ethToDom(ethAmount);
        require(_domWeiTokenTotalForEth >= feeInDom, "Insufficient funds 1");

        _mintOrBuyDNAFromOwner(_domWeiTokenTotalForEth, _buyer);

        uint _onlyDnameFeeDNAWei = feeInDom.sub(discountNoOfTokens);
        _chargeFeeAndBurn(_buyer, _onlyDnameFeeDNAWei);

        return true;
    }

    function registerOrExtendDnameWithEth(uint _dnaNameChars, string calldata _tld,
        uint _durationInYears,bool _transfer, address _msgSender) external payable returns(bool){
        require(msg.value > 0, "Insufficient funds");
        require(_dnaNameChars > 0, "Wrong dna name length");
        require(bytes(_tld).length > 1, "Wrong dna tld length");
        require(_durationInYears > 0, "Wrong dna year duration");
        require(directMintAllowed, "This feature is not allowed!");

        address _buyersAddress = msg.sender;
        if(msg.sender == nameNFTContractAddr){
            _buyersAddress = _msgSender;
        }

        _registerOrExtendDnameWithEth(_dnaNameChars, _tld, _durationInYears, _buyersAddress,
            msg.value, _transfer);
        return true;
    }

    function _registerOrExtendDnameWithDNA(uint _dnaNameChars, string calldata _tld, uint _durationInYears,
        address _buyer, bool _transfer) private {
        (uint _feeInDomWei, uint discountNoOfTokens) = calculateDnameFeeInDom(_dnaNameChars, _tld,
            _durationInYears, _transfer);
        require(balanceOf[_buyer] >= _feeInDomWei, "Insufficient funds 1");

        uint _onlyDnameFeeDNAWei = _feeInDomWei.sub(discountNoOfTokens);
        _chargeFeeAndBurn(_buyer, _onlyDnameFeeDNAWei);
    }

    function registerOrExtendDnameWithDNA(uint _dnaNameChars, string calldata _tld,
        uint _durationInYears, bool _transfer, address _msgSender)
    external returns (bool){
        require(_dnaNameChars > 0, "Wrong dna name length");
        require(bytes(_tld).length > 1, "Wrong dna tld length");
        require(_durationInYears > 0, "Wrong dna year duration");

        address _buyersAddress = msg.sender;
        if(msg.sender == nameNFTContractAddr){
            _buyersAddress = _msgSender;
        }

        _registerOrExtendDnameWithDNA(_dnaNameChars, _tld, _durationInYears, _buyersAddress, _transfer);
        return true;
    }

    function chargeDnameReleaseFeeFromEthValue(address _msgSender) external payable returns(bool){
        uint amountToChargeInUsd = _dnaAndTokenFees[uint(FEE_TYPES.DNAME_RELEASE_FEE_IN_USD)];
        uint ethValueInUsd = po.ethToUsd(msg.value);
        require(ethValueInUsd >= amountToChargeInUsd, "Insufficient Eth balance!");

        address _buyersAddress = msg.sender;
        if(msg.sender == nameNFTContractAddr){
            _buyersAddress = _msgSender;
        }
        uint domAmount = po.ethToDom(uint(msg.value));
        _mintOrBuyDNAFromOwner(domAmount, _buyersAddress);

        uint _feeInDom = po.usdToDom(amountToChargeInUsd);
        _chargeFeeAndBurn(_buyersAddress, _feeInDom);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PriceOracle is Ownable{
    using SafeMath for uint256;
    AggregatorV3Interface internal priceFeedETHUSD;
    AggregatorV3Interface internal priceFeedDNAUSD;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    //Contracts lists : https://docs.chain.link/docs/ethereum-addresses/
    constructor(AggregatorV3Interface _priceFeedETHUSD
    , AggregatorV3Interface _priceFeedDNAUSD) {
        priceFeedETHUSD = _priceFeedETHUSD;
        priceFeedDNAUSD = _priceFeedDNAUSD;
    }

    function setUSDETHPriceAggregatorContract(address ethUsdAggr) external onlyOwner{
        ethUsdAggr = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e; //TODO Remove these
        priceFeedETHUSD = AggregatorV3Interface(ethUsdAggr);
    }

    function setUSDDNAPriceAggregatorContract(address dnaUsdAggr) external onlyOwner{
        dnaUsdAggr = 0x48731cF7e84dc94C5f84577882c14Be11a5B7456; //TODO Remove these
        priceFeedDNAUSD = AggregatorV3Interface(dnaUsdAggr);
    }
    /**
     * Returns the latest price
     */
    function getLatestPriceETHUSD() external view returns (uint) {
        (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeedETHUSD.latestRoundData();
        uint decim = 10**priceFeedETHUSD.decimals();
        //  return uint(price)/decim;
        return uint(price);
    }

    function getLatestPriceDNAUSD() external view returns (uint) {
        (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeedDNAUSD.latestRoundData();
        uint decim = 10**priceFeedDNAUSD.decimals();
        //return uint(price)/decim;
        return uint(price);
    }

    function ethToDom(uint _weiAmount) external pure returns(uint){
        uint dnaUsd =        1_000_000_000_000_000;//getLatestPriceDNAUSD();// TODO Uncomment it
        uint ethUsd = 2000_000_000_000_000_000_000;//getLatestPriceETHUSD(); // TODO Uncomment it
        return _weiAmount.mul(ethUsd).div(dnaUsd);
    }

    function ethToUsd(uint _weiAmount) external pure returns(uint){
        uint ethUsd = 2000_000_000_000_000_000_000;//getLatestPriceETHUSD(); // TODO Uncomment it
        return _weiAmount.mul(ethUsd).div(10**18);
    }

    //usd amount without precision/decimal points just integer number for e.g 1 5 10 etc
    function usdToDom(uint _usdAmount) external pure returns(uint){
        uint dnaUsd =  1000_000_000_000_000_000_000;//getLatestPriceDNAUSD();// TODO Uncomment it
        return _usdAmount.mul(dnaUsd);
    }
}

library Utils {
    using SafeMath for uint256;

    modifier isValidDnameNameSize(string calldata _dname){
        uint strLen = bytes(_dname).length;
        require( strLen >= 3, "Not a valid dnaain name, use .tld for full dna name." );
        _;
    }

    function extractTLD(string calldata _dname) isValidDnameNameSize(_dname) external pure returns(string memory){
        uint256 dnameLen = bytes(_dname).length;
        uint256 position = dnameLen - 1;

        bytes memory dnaNamBytes = bytes(_dname);

        while(position !=0 && uint8(dnaNamBytes[position]) != uint8(0x2e)){// '.' ascii code
            position--;
        }
        require(position != 0 && position < (dnameLen-1), "Invalid dna name");

        bytes memory _tempTLD = new bytes(dnameLen-position);
        uint tldIndex = 0;
        while(position < dnameLen){
            _tempTLD[tldIndex++] = dnaNamBytes[position++];
        }
        return string(_tempTLD);
    }

    function getDomNameHashFromName(string calldata _dname) external pure returns(uint){
        return uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(_dname)))));
    }

    function getUTFCharsLenInName(string calldata _dname, uint tldLength) external pure returns(uint) {
        uint uniqueUTFChars = 0;
        bytes memory dnaBytes = bytes(_dname);
        require(dnaBytes.length > tldLength, "Invalid dna name");
        uint index = 0;
        while(index < (dnaBytes.length - tldLength) ){
            if((dnaBytes[index++] & 0xc0) != 0x80){ //With the two high bits equals to 10xx xxxx, it's a continuation byte.
                uniqueUTFChars++;
            }
        }
        return uniqueUTFChars;
    }

    function toHexString(address addr) external pure returns (string memory) {
        bytes16 HEX_SYMBOLS = "0123456789abcdef";
        uint256 length = 20;
        uint256 value = uint256(uint160(addr));
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "String hex length insufficient");
        return string(buffer);
    }
}

contract TLDRegister is Ownable{
    using SafeMath for uint256;

    mapping(string => address) public topLDControllers; //.ape .punk .web3 => the controller address

    modifier isTLDController(string calldata _tld) {
        require(topLDControllers[_tld] != address(0) && topLDControllers[_tld] == msg.sender, "You are not a TLD Controller");
        _;
    }

    modifier tLDSizeValid(string calldata _tld) {  // . and at least 1 letter, so minimum 2 letters tld
        uint8 MIN_TLD_LENGTH = 2;
        require( bytes(_tld).length >= MIN_TLD_LENGTH, "TLD must be . + character, not less than 2 chars !");
        _;
    }

    modifier isNonZeroAddress(address _addr) {
        require( _addr != address(0), "Zero address is not accepted!");
        _;
    }

    event TLD_CONTROLLER_UPDATED(string tld, address lastController, address _newController, address msgSender);

    function setTLDController(string calldata _tld, address _newController) onlyOwner tLDSizeValid(_tld)
    isNonZeroAddress(_newController) external{
        _updateTldController(_tld, _newController);
    }

    function updateTLDController(string calldata _tld, address _newController) isTLDController(_tld)
    tLDSizeValid(_tld) isNonZeroAddress(_newController) external{
        _updateTldController(_tld,  _newController);
    }

    function _updateTldController(string calldata _tld, address _newController) private {
        address lastController = topLDControllers[_tld];
        topLDControllers[_tld] = _newController;
        emit TLD_CONTROLLER_UPDATED(_tld, lastController, _newController, msg.sender);
    }
}

contract SLDRegister is TLDRegister{
    using SafeMath for uint256;

    mapping(uint256 => SLDEntry) public sldRegister;

    struct SLDEntry {
        string dname;
        string tld;
        uint256 ttl;
        address sldOwner;
        address sldController;
    }

    modifier onlySldOwner(uint _dnaId) {
        require(sldRegister[_dnaId].sldOwner != address(0) && sldRegister[_dnaId].sldOwner == msg.sender, "Not SLD Owner");
        _;
    }

    modifier onlySldController(uint _dnaId) {
        require(sldRegister[_dnaId].sldController != address(0) && sldRegister[_dnaId].sldController == msg.sender, "Not SLD Controller");
        _;
    }

    event EXPIRED_NAME_MOVED_TO_TLD_CONTROLLER(uint _dnaId, address lastOwner, address newOwner, uint ttl, address msgSender);
    event EXPIRED_NAME_RELEASED(uint _dnaId, address lastOwner, address msgSender);
    event NAME_CONTROLLER_UPDATED(uint _dnaId, address lastController, address _newSldController, address msgSender);
    event NAME_UPDATED(uint _dnaId, address _newOwner, address _newController, uint _ttl, address msgSender);

    function updateSLDController(uint _dnaId, address _newSldController) onlySldOwner(_dnaId) external {
        address lastController = sldRegister[_dnaId].sldController;
        sldRegister[_dnaId].sldController = _newSldController;
        emit NAME_CONTROLLER_UPDATED(_dnaId, lastController, _newSldController, msg.sender);
    }

    function sldRegistered(string calldata _dname) public view returns(bool){
        uint _dnaId = Utils.getDomNameHashFromName(_dname);
        return (sldRegister[_dnaId].sldOwner != address(0));
    }

    function _addSLD(uint _dnaId, string memory _tld, string calldata _dname, address _sldController, uint256 _ttl) internal {
        SLDEntry memory newSld;
        newSld.tld = _tld;
        newSld.dname = _dname;
        newSld.ttl = _ttl;
        newSld.sldOwner = msg.sender;
        newSld.sldController = _sldController;
        sldRegister[_dnaId] = newSld;
    }

    function _updateSLD(uint _dnaId, address _newOwner, address _newController, uint _ttl) internal {
        sldRegister[_dnaId].sldOwner = _newOwner;
        sldRegister[_dnaId].sldController = _newController;
        sldRegister[_dnaId].ttl = _ttl;
        emit NAME_UPDATED(_dnaId, _newOwner, _newController, _ttl, msg.sender);
    }

    function _moveExpiredDNameToTLDController(uint _dnaId) internal {
        string memory _tld = sldRegister[_dnaId].tld;
        address lastOwner = sldRegister[_dnaId].sldOwner;
        sldRegister[_dnaId].sldOwner = topLDControllers[_tld];
        sldRegister[_dnaId].sldController = topLDControllers[_tld];
        sldRegister[_dnaId].ttl = block.timestamp.add(uint(15).mul(365).mul(24).mul(60).mul(60));
        emit EXPIRED_NAME_MOVED_TO_TLD_CONTROLLER(_dnaId, lastOwner, sldRegister[_dnaId].sldOwner, sldRegister[_dnaId].ttl, msg.sender);
    }

    function _releaseExpiredDName(uint _dnaId) internal {
        address lastOwner = sldRegister[_dnaId].sldOwner;
        sldRegister[_dnaId].tld = '';
        sldRegister[_dnaId].dname = '';
        sldRegister[_dnaId].ttl = 0;
        sldRegister[_dnaId].sldOwner = address(0);
        sldRegister[_dnaId].sldController = address(0);
        emit EXPIRED_NAME_RELEASED(_dnaId, lastOwner, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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