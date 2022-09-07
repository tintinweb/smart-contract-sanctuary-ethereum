/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner; 
    // constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

abstract contract ERC721G {

    // Standard ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved,
        uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator,
        bool approved);

    // // ERC721G Events
    // event TokenStaked(uint256 indexed tokenId_, address indexed staker,
    //     uint256 timestamp_);
    // event TokenUnstaked(uint256 indexed tokenid_, address indexed staker,
    //     uint256 timestamp_, uint256 totalTimeStaked_);
    
    // Standard ERC721 Global Variables
    string public name; // Token Name
    string public symbol; // Token Symbol

    // ERC721G Global Variables
    uint256 public tokenIndex; // The running index for the next TokenId
    uint256 public immutable startTokenId; // Bytes Storage for the starting TokenId
    uint256 public immutable maxBatchSize;

    // Staking Address supports Proxy
    // address public immutable stakingAddress = address(this); // The staking address
    function stakingAddress() public view returns (address) {
        return address(this);
    }

    /** @dev instructions:
     *  name_ sets the token name
     *  symbol_ sets the token symbol
     *  startId_ sets the starting tokenId (recommended 0-1)
     *  maxBatchSize_ sets the maximum batch size for each mint (recommended 5-20)
     */
    constructor(
    string memory name_, string memory symbol_, 
    uint256 startId_, uint256 maxBatchSize_) {
        name = name_;
        symbol = symbol_;
        tokenIndex = startId_;
        startTokenId = startId_;
        maxBatchSize = maxBatchSize_;
    }

    // ERC721G Structs
    struct OwnerStruct {
        address owner; // stores owner address for OwnerOf
        uint32 lastTransfer; // stores the last transfer of the token
        uint32 stakeTimestamp; // stores the stake timestamp in _setStakeTimestamp()
        uint32 totalTimeStaked; // stores the total time staked accumulated
    }

    struct BalanceStruct {
        uint32 balance; // stores the token balance of the address
        uint32 mintedAmount; // stores the minted amount of the address on mint
        // 24 Free Bytes
    }

    // ERC721G Mappings
    mapping(uint256 => OwnerStruct) public _tokenData; // ownerOf replacement
    mapping(address => BalanceStruct) public _balanceData; // balanceOf replacement
    mapping(uint256 => OwnerStruct) public mintIndex; // uninitialized ownerOf pointer

    // ERC721 Mappings
    mapping(uint256 => address) public getApproved; // for single token approvals
    mapping(address => mapping(address => bool)) public isApprovedForAll; // approveall

    // TIME by 0xInuarashi 
    function _getBlockTimestampCompressed() public virtual view returns (uint32) {
        return uint32(block.timestamp / 10);
    }
    function _compressTimestamp(uint256 timestamp_) public virtual view
    returns (uint32) {
        return uint32(timestamp_ / 10);
    }
    function _expandTimestamp(uint32 timestamp_) public virtual view
    returns (uint256) {
        return uint256(timestamp_) * 10;
    }
    
    function getLastTransfer(uint256 tokenId_) public virtual view
    returns (uint256) {
        return _expandTimestamp(_getTokenDataOf(tokenId_).lastTransfer);
    }
    function getStakeTimestamp(uint256 tokenId_) public virtual view
    returns (uint256) {
        return _expandTimestamp(_getTokenDataOf(tokenId_).stakeTimestamp);
    }
    function getTotalTimeStaked(uint256 tokenId_) public virtual view
    returns (uint256) {
        return _expandTimestamp(_getTokenDataOf(tokenId_).totalTimeStaked);
    }

    ///// ERC721G: ERC721-Like Simple Read Outputs /////
    function totalSupply() public virtual view returns (uint256) {
        return tokenIndex - startTokenId;
    }
    function balanceOf(address address_) public virtual view returns (uint256) {
        return _balanceData[address_].balance;
    }

    ///// ERC721G: Range-Based Logic /////
    
    /** @dev explanation:
     *  _getTokenDataOf() finds and returns either the (and in priority)
     *      - the initialized storage pointer from _tokenData
     *      - the uninitialized storage pointer from mintIndex
     * 
     *  if the _tokenData storage slot is populated, return it
     *  otherwise, do a reverse-lookup to find the uninitialized pointer from mintIndex
     */
    function _getTokenDataOf(uint256 tokenId_) public virtual view
    returns (OwnerStruct memory) {
        // The tokenId must be above startTokenId only
        require(tokenId_ >= startTokenId, "TokenId below starting Id!");
        
        // If the _tokenData is initialized (not 0x0), return the _tokenData
        if (_tokenData[tokenId_].owner != address(0)
            || tokenId_ >= tokenIndex) {
            return _tokenData[tokenId_];
        }

        // Else, do a reverse-lookup to find  the corresponding uninitialized pointer
        else { unchecked {
            uint256 _lowerRange = tokenId_;
            while (mintIndex[_lowerRange].owner == address(0)) { _lowerRange--; }
            return mintIndex[_lowerRange];
        }}
    }

    /** @dev explanation: 
     *  ownerOf calls _getTokenDataOf() which returns either the initialized or 
     *  uninitialized pointer. 
     *  Then, it checks if the token is staked or not through stakeTimestamp.
     *  If the token is staked, return the stakingAddress, otherwise, return the owner.
     */
    function ownerOf(uint256 tokenId_) public virtual view returns (address) {
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        return _OwnerStruct.stakeTimestamp == 0 ? _OwnerStruct.owner : stakingAddress();
    }

    /** @dev explanation:
     *  _trueOwnerOf() calls _getTokenDataOf() which returns either the initialized or
     *  uninitialized pointer.
     *  It returns the owner directly without any checks. 
     *  Used internally for proving the staker address on unstake.
     */
    function _trueOwnerOf(uint256 tokenId_) public virtual view returns (address) {
        return _getTokenDataOf(tokenId_).owner;
    }

    ///// ERC721G: Internal Single-Contract Staking Logic /////
    
    /** @dev explanation:
     *  _initializeTokenIf() is used as a beginning-hook to functions that require
     *  that the token is explicitly INITIALIZED before the function is able to be used.
     *  It will check if the _tokenData slot is initialized or not. 
     *  If it is not, it will initialize it.
     *  Used internally for staking logic.
     */
    function _initializeTokenIf(uint256 tokenId_, OwnerStruct memory _OwnerStruct) 
    internal virtual {
        // If the target _tokenData is not initialized, initialize it.
        if (_tokenData[tokenId_].owner == address(0)) {
            _tokenData[tokenId_] = _OwnerStruct;
        }
    }

    /** @dev explanation:
     *  _setStakeTimestamp() is our staking / unstaking logic.
     *  If timestamp_ is > 0, the action is "stake"
     *  If timestamp_ is == 0, the action is "unstake"
     * 
     *  We grab the tokenData using _getTokenDataOf and then read its values.
     *  As this function requires INITIALIZED tokens only, we call _initializeTokenIf()
     *  to initialize any token using this function first.
     * 
     *  Processing of the function is explained in in-line comments.
     */
    function _setStakeTimestamp(uint256 tokenId_, uint256 timestamp_)
    internal virtual returns (address) {
        // First, call _getTokenDataOf and grab the relevant tokenData
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        address _owner = _OwnerStruct.owner;
        uint32 _stakeTimestamp = _OwnerStruct.stakeTimestamp;

        // _setStakeTimestamp requires initialization
        _initializeTokenIf(tokenId_, _OwnerStruct);

        // Clear any token approvals
        delete getApproved[tokenId_];

        // if timestamp_ > 0, the action is "stake"
        if (timestamp_ > 0) {
            // Make sure that the token is not staked already
            require(_stakeTimestamp == 0,
                "ERC721G: _setStakeTimestamp() already staked");
            
            // Callbrate balances between staker and stakingAddress
            unchecked { 
                _balanceData[_owner].balance--;
                _balanceData[stakingAddress()].balance++;
            }

            // Emit Transfer event from trueOwner
            emit Transfer(_owner, stakingAddress(), tokenId_);
        }

        // if timestamp_ == 0, the action is "unstake"
        else {
            // Make sure the token is not staked
            require(_stakeTimestamp != 0,
                "ERC721G: _setStakeTimestamp() already unstaked");
            
            // Callibrate balances between stakingAddress and staker
            unchecked {
                _balanceData[_owner].balance++;
                _balanceData[stakingAddress()].balance--;
            }
            
            // we add total time staked to the token on unstake
            uint32 _timeStaked = _getBlockTimestampCompressed() - _stakeTimestamp;
            _tokenData[tokenId_].totalTimeStaked += _timeStaked;

            // Emit Transfer event to trueOwner
            emit Transfer(stakingAddress(), _owner, tokenId_);
        }

        // Set the stakeTimestamp to timestamp_
        _tokenData[tokenId_].stakeTimestamp = _compressTimestamp(timestamp_);

        // We save internal gas by returning the owner for a follow-up function
        return _owner;
    }

    /** @dev explanation:
     *  _stake() works like an extended function of _setStakeTimestamp()
     *  where the logic of _setStakeTimestamp() runs and returns the _owner address
     *  afterwards, we do the post-hook required processing to finish the staking logic 
     *  in this function.
     * 
     *  Processing logic explained in in-line comments.
     */
    function _stake(uint256 tokenId_) internal virtual returns (address) {
        // set the stakeTimestamp to block.timestamp and return the owner
        return _setStakeTimestamp(tokenId_, block.timestamp);
    }

    /** @dev explanation:
     *  _unstake() works like an extended unction of _setStakeTimestamp()
     *  where the logic of _setStakeTimestamp() runs and returns the _owner address
     *  afterwards, we do the post-hook required processing to finish the unstaking logic
     *  in this function.
     * 
     *  Processing logic explained in in-line comments.
     */
    function _unstake(uint256 tokenId_) internal virtual returns(address) {
        // set the stakeTimestamp to 0 and return the owner
        return _setStakeTimestamp(tokenId_, 0);
    }

    /** @dev explanation:
     *  _mintAndStakeInternal() is the internal mintAndStake function that is called
     *  to mintAndStake tokens to users. 
     * 
     *  It populates mintIndex with the phantom-mint data (owner, lastTransferTime)
     *  as well as the phantom-stake data (stakeTimestamp)
     * 
     *  Then, it emits the necessary phantom events to replicate the behavior as canon.
     * 
     *  Further logic explained in in-line comments.
     */
    function _mintAndStakeInternal(address to_, uint256 amount_) internal virtual {
        // we cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintAndStakeInternal to 0x0");

        // we limit max mints per SSTORE to prevent expensive gas lookup
        require(amount_ <= maxBatchSize, 
            "ERC721G: _mintAndStakeInternal over maxBatchSize");

        // process the required variables to write to mintIndex 
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;
        uint32 _currentTime = _getBlockTimestampCompressed();

        // write to the mintIndex to store the OwnerStruct for uninitialized tokenData
        mintIndex[_startId] = OwnerStruct(
            to_, // the address the token is minted to
            _currentTime, // the last transfer time
            _currentTime, // the curent time of staking
            0 // the accumulated time staked
        );

        unchecked { 
            // we add the balance to the stakingAddress through our staking logic
            _balanceData[stakingAddress()].balance += uint32(amount_);

            // we add the mintedAmount to the to_ through our minting logic
            _balanceData[to_].mintedAmount += uint32(amount_);

            // emit phantom mint to to_, then emit a staking transfer
            do { 
                emit Transfer(address(0), to_, _startId);
                emit Transfer(to_, stakingAddress(), _startId);

                // /** @dev testing:
                // *  emitting a TokenStaked event for testing
                // */
                // emit TokenStaked(_startId, to_, _currentTime);

            } while (++_startId < _endId);
        }

        // set the new tokenIndex to the _endId
        tokenIndex = _endId;
    }

    /** @dev explanation: 
     *  _mintAndStake() calls _mintAndStakeInternal() but calls it using a while-loop
     *  based on the required minting amount to stay within the bounds of 
     *  max mints per batch (maxBatchSize)
     */
    function _mintAndStake(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintAndStakeInternal(to_, maxBatchSize);
        }
        _mintAndStakeInternal(to_, _amountToMint);
    }

    ///// ERC721G Range-Based Internal Minting Logic /////
    
    /** @dev explanation:
     *  _mintInternal() is our internal batch minting logic. 
     *  First, we store the uninitialized pointer at mintIndex of _startId
     *  Then, we process the balances changes
     *  Finally, we phantom-mint the tokens using Transfer events loop.
     */
    function _mintInternal(address to_, uint256 amount_) internal virtual {
        // cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintInternal to 0x0");

        // we limit max mints to prevent expensive gas lookup
        require(amount_ <= maxBatchSize, 
            "ERC721G: _mintInternal over maxBatchSize");

        // process the token id data
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;

        // push the required phantom mint data to mintIndex
        mintIndex[_startId].owner = to_;
        mintIndex[_startId].lastTransfer = _getBlockTimestampCompressed();

        // process the balance changes and do a loop to phantom-mint the tokens to to_
        unchecked { 
            _balanceData[to_].balance += uint32(amount_);
            _balanceData[to_].mintedAmount += uint32(amount_);

            do { emit Transfer(address(0), to_, _startId); } while (++_startId < _endId);
        }

        // set the new token index
        tokenIndex = _endId;
    }

    /** @dev explanation:
     *  _mint() is the function that calls _mintInternal() using a while-loop
     *  based on the maximum batch size (maxBatchSize)
     */
    function _mint(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(to_, maxBatchSize);
        }
        _mintInternal(to_, _amountToMint);
    }

    /** @dev explanation:
     *  _transfer() is the internal function that transfers the token from_ to to_
     *  it has ERC721-standard require checks
     *  and then uses solmate-style approval clearing
     * 
     *  afterwards, it sets the _tokenData to the data of the to_ (transferee) as well as
     *  set the balanceData.
     *  
     *  this results in INITIALIZATION of the token, if it has not been initialized yet. 
     */
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        // the from_ address must be the ownerOf
        require(from_ == ownerOf(tokenId_), "ERC721G: _transfer != ownerOf");
        // cannot transfer to 0x0
        require(to_ != address(0), "ERC721G: _transfer to 0x0");

        // delete any approvals
        delete getApproved[tokenId_];

        // set _tokenData to to_
        _tokenData[tokenId_].owner = to_;
        _tokenData[tokenId_].lastTransfer = _getBlockTimestampCompressed();

        // update the balance data
        unchecked { 
            _balanceData[from_].balance--;
            _balanceData[to_].balance++;
        }

        // emit a standard Transfer
        emit Transfer(from_, to_, tokenId_);
    }

    ///// ERC721G: User-Enabled Out-of-the-box Staking Functionality /////
    /** @dev clarification:
     *  As a developer, you DO NOT have to enable these functions, or use them
     *  in the way defined in this section. 
     * 
     *  The functions in this section are just out-of-the-box plug-and-play staking
     *  which is enabled IMMEDIATELY.
     *  (As well as some useful view-functions)
     * 
     *  You can choose to call the internal staking functions yourself, to create 
     *  custom staking logic based on the section (n-2) above.
     */

    /** @dev explanation:
     *  this is a staking function that receives calldata tokenIds_ array
     *  and loops to call internal _stake in a gas-efficient way 
     *  written in a shorthand-style syntax
     */
    function stake(uint256[] calldata tokenIds_) public virtual {
        uint256 i;
        uint256 l = tokenIds_.length;
        while (i < l) { 
            // stake and return the owner's address
            address _owner = _stake(tokenIds_[i]); 
            // make sure the msg.sender is the owner
            require(msg.sender == _owner, "You are not the owner!");
            unchecked {++i;}
        }
    }
    /** @dev explanation:
     *  this is an unstaking function that receives calldata tokenIds_ array
     *  and loops to call internal _unstake in a gas-efficient way 
     *  written in a shorthand-style syntax
     */
    function unstake(uint256[] calldata tokenIds_) public virtual {
        uint256 i;
        uint256 l = tokenIds_.length;
        while (i < l) { 
            // unstake and return the owner's address
            address _owner = _unstake(tokenIds_[i]); 
            // make sure the msg.sender is the owner
            require(msg.sender == _owner, "You are not the owner!");
            unchecked {++i;}
        }
    }

    ///// ERC721G: User-Enabled Out-of-the-box Staking View Functions /////
    /** @dev explanation:
     *  balanceOfStaked loops through the entire tokens using 
     *  startTokenId as the start pointer, and 
     *  tokenIndex (current-next tokenId) as the end pointer
     * 
     *  it checks if the _trueOwnerOf() is the address_ or not
     *  and if the owner() is not the address, indicating the 
     *  state that the token is staked.
     * 
     *  if so, it increases the balance. after the loop, it returns the balance.
     * 
     *  this is mainly for external view only. 
     *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
     */
    function balanceOfStaked(address address_) public virtual view 
    returns (uint256) {
        uint256 _balance;
        uint256 i = startTokenId;
        uint256 max = tokenIndex;
        while (i < max) {
            if (ownerOf(i) != address_ && _trueOwnerOf(i) == address_) {
                _balance++;
            }
            unchecked { ++i; }
        }
        return _balance;
    }

    /** @dev explanation:
     *  walletOfOwnerStaked calls balanceOfStaked to get the staked 
     *  balance of a user. Afterwards, it runs staked-checking logic
     *  to figure out the tokenIds that the user has staked
     *  and then returns it in walletOfOwner fashion.
     * 
     *  this is mainly for external view only.
     *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
     */
    function walletOfOwnerStaked(address address_) public virtual view
    returns (uint256[] memory) {
        uint256 _balance = balanceOfStaked(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _currentIndex;
        uint256 i = startTokenId;
        while (_currentIndex < _balance) {
            if (ownerOf(i) != address_ && _trueOwnerOf(i) == address_) {
                _tokens[_currentIndex++] = i;
            }
            unchecked { ++i; }
        }
        return _tokens;
    }

    /** @dev explanation:
     *  balanceOf of the address returns UNSTAKED tokens only.
     *  to get the total balance of the user containing both STAKED and UNSTAKED tokens,
     *  we use this function. 
     * 
     *  this is mainly for external view only.
     *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
     */
    function totalBalanceOf(address address_) public virtual view returns (uint256) {
        return balanceOf(address_) + balanceOfStaked(address_);
    }

    /** @dev explanation:
     *  totalTimeStakedOfToken returns the accumulative total time staked of a tokenId
     *  it reads from the totalTimeStaked of the tokenId_ and adds it with 
     *  a calculation of pending time staked and returns the sum of both values.
     * 
     *  this is mainly for external view / use only.
     *  this function can be interfaced with contract writes.
     */
    function totalTimeStakedOfToken(uint256 tokenId_) public virtual view 
    returns (uint256) {
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        uint256 _totalTimeStakedOnToken = _expandTimestamp(_OwnerStruct.totalTimeStaked);
        uint256 _totalTimeStakedPending = 
            _OwnerStruct.stakeTimestamp > 0 ?
            _expandTimestamp(
                _getBlockTimestampCompressed() - _OwnerStruct.stakeTimestamp) : 
                0;

        return _totalTimeStakedOnToken + _totalTimeStakedPending;
    }

    /** @dev explanation:
     *  totalTimeStakedOfTokens just returns an array of totalTimeStakedOfToken
     *  based on tokenIds_ calldata.
     *  
     *  this is mainly for external view / use only.
     *  this function can be interfaced with contract writes... however
     *  BE CAREFUL and USE IT CORRECTLY. 
     *  (dont pass in 5000 tokenIds_ in a write function)
     */
    function totalTimeStakedOfTokens(uint256[] calldata tokenIds_) public
    virtual view returns (uint256[] memory) {
        uint256 i;
        uint256 l = tokenIds_.length;
        uint256[] memory _totalTimeStakeds = new uint256[] (l);
        while (i < l) {
            _totalTimeStakeds[i] = totalTimeStakedOfToken(tokenIds_[i]);
            unchecked { ++i; }
        }
        return _totalTimeStakeds;
    }

    ///// ERC721G: ERC721 Standard Logic /////
    /** @dev clarification:
     *  no explanations here as these are standard ERC721 logics.
     *  the reason that we can use standard ERC721 logics is because
     *  the ERC721G logic is compartmentalized and supports internally 
     *  these ERC721 logics without any need of modification.
     */
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal 
    view virtual returns (bool) {
        address _owner = ownerOf(tokenId_);
        return (
            // "i am the owner of the token, and i am transferring it"
            _owner == spender_
            // "the token's approved spender is me"
            || getApproved[tokenId_] == spender_
            // "the owner has approved me to spend all his tokens"
            || isApprovedForAll[_owner][spender_]);
    }
    
    /** @dev clarification:
     *  sets a specific address to be able to spend a specific token.
     */
    function _approve(address to_, uint256 tokenId_) internal virtual {
        getApproved[tokenId_] = to_;
        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }

    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(
            // "i am the owner, and i am approving this token."
            _owner == msg.sender 
            // "i am isApprovedForAll, so i can approve this token too."
            || isApprovedForAll[_owner][msg.sender],
            "ERC721G: approve not authorized");

        _approve(to_, tokenId_);
    }

    function _setApprovalForAll(address owner_, address operator_, bool approved_) 
    internal virtual {
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        // this function can only be used as self-approvalforall for others. 
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    function _exists(uint256 tokenId_) internal virtual view returns (bool) {
        return ownerOf(tokenId_) != address(0);
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_),
            "ERC721G: transferFrom unauthorized");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_,
    bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.call(abi.encodeWithSelector(
                0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, 
                "ERC721G: safeTransferFrom to_ non-ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function supportsInterface(bytes4 iid_) public virtual view returns (bool) {
        return iid_ == 0x01ffc9a7 || iid_ == 0x80ac58cd || iid_ == 0x5b5e139f; 
    }

    function walletOfOwner(address address_) public virtual view 
    returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _currentIndex;
        uint256 i = startTokenId;
        while (_currentIndex < _balance) {
            if (ownerOf(i) == address_) { _tokens[_currentIndex++] = i; }
            unchecked { ++i; }
        }
        return _tokens;
    }

    function tokenURI(uint256 tokenId_) public virtual view returns (string memory) {}

    // Proxy Padding
    bytes32[50] private proxyPadding;

}

abstract contract Minterable is Ownable {
    mapping(address => bool) public minters;
    modifier onlyMinter { require(minters[msg.sender], "Not Minter!"); _; }
    event MinterSet(address newMinter, bool status);
    function setMinter(address address_, bool bool_) external onlyOwner {
        minters[address_] = bool_;
        emit MinterSet(address_, bool_);
    }
}

contract GangsterAllStarEvolution is ERC721G, Ownable, Minterable {

    // Set the base ERC721G Constructor
    constructor() ERC721G("Gangster All Star: Evolution", "GAS:EVO", 1, 20) {}

    // Proxy Initializer Logic
    bool proxyIsInitialized;
    function proxyInitialize(address newOwner) external {
        require(!proxyIsInitialized);
        proxyIsInitialized = true;
        
        // Hardcode
        owner = newOwner;
        name = "Gangster All Star: Evolution";
        symbol = "GAS:EVO";
        tokenIndex = 1;
    }

    // On-Chain Generation Seed for Generative Art Generation
    bytes32 public generationSeed;
    function pullGenerationSeed() external onlyOwner {
        generationSeed = keccak256(abi.encodePacked(
            block.timestamp, block.number, block.difficulty,
            block.coinbase, block.gaslimit, blockhash(block.number)
        ));
    }

    // Define the NFT Constant Params
    uint256 public constant maxSupply = 7777;

    // Define NFT Global Params
    bool public stakingIsEnabled;
    bool public unstakingIsEnabled;
    function O_setStakingIsEnabled(bool bool_) external onlyOwner {
        stakingIsEnabled = bool_; }
    function O_setUnstakingIsEnabled(bool bool_) external onlyOwner {
        unstakingIsEnabled = bool_; }

    // Internal Overrides
    function _mint(address address_, uint256 amount_) internal override {
        require(maxSupply >= (totalSupply() + amount_),
            "ERC721G: _mint(): exceeds maxSupply");
        ERC721G._mint(address_, amount_);
    }

    // Stake / Unstake Overrides for Future Compatibility
    function stake(uint256[] calldata tokenIds_) public override {
        require(stakingIsEnabled, "Staking functionality not enabled yet!");
        ERC721G.stake(tokenIds_);
    }
    function unstake(uint256[] calldata tokenIds_) public override {
        require(unstakingIsEnabled, "Unstaking functionality not enabled yet!");
        ERC721G.unstake(tokenIds_);
    }

    // Internal Functions
    function _mintMany(address[] memory addresses_, uint256[] memory amounts_)
    internal {
        require(addresses_.length == amounts_.length, "Array lengths mismatch!");
        for (uint256 i = 0; i < addresses_.length;) {
            _mint(addresses_[i], amounts_[i]);
            unchecked { ++i; }
        }
    }

    // Controllerable Minting
    function mintAsController(address to_, uint256 amount_) external onlyMinter {
        _mint(to_, amount_);
    }
    function mintAsControllerMany(address[] calldata tos_, uint256[] calldata amounts_)
    external onlyMinter {
        _mintMany(tos_, amounts_);
    }

    // Token URI Configurations
    string internal baseURI;
    string internal baseURI_EXT; 

    function O_setBaseURI(string calldata uri_) external onlyOwner {
        baseURI = uri_; 
    }
    function O_setBaseURI_EXT(string calldata ext_) external onlyOwner {
        baseURI_EXT = ext_; 
    }
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; }
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
            48 + uint256(value_ % 10 ))); value_ /= 10; }
        return string(_buffer); 
    }
    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        // PoS Merge-Safe
        if (block.chainid != 1) return "";
        return string(abi.encodePacked(baseURI, _toString(tokenId_), baseURI_EXT));
    }

    // Proxy Padding
    bytes32[50] private proxyPadding;

}