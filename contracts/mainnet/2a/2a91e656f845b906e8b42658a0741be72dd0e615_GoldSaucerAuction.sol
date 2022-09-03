/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Gold Saucer Auction by 0xInuarashi
// Project: Gangster All Star

///////////////////////////////////////////////////////
/////                   Ownable                   /////
///////////////////////////////////////////////////////

abstract contract Ownable {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

///////////////////////////////////////////////////////
/////             Payable Governance              /////
///////////////////////////////////////////////////////

abstract contract PayableGovernance is Ownable {
    // Special Access
    address public payableGovernanceSetter;
    constructor() payable { payableGovernanceSetter = msg.sender; }
    modifier onlyPayableGovernanceSetter {
        require(msg.sender == payableGovernanceSetter, 
            "PayableGovernance: Caller is not Setter!"); _; }
    function reouncePayableGovernancePermissions() public onlyPayableGovernanceSetter {
        payableGovernanceSetter = address(0x0); }

    // Receivable Fallback
    event Received(address from, uint amount);
    receive() external payable { emit Received(msg.sender, msg.value); }

    // Required Variables
    address payable[] internal _payableGovernanceAddresses;
    uint256[] internal _payableGovernanceShares;    
    mapping(address => bool) public addressToEmergencyUnlocked;

    // Withdraw Functionality
    function _withdraw(address payable address_, uint256 amount_) internal {
        (bool success, ) = payable(address_).call{value: amount_}("");
        require(success, "Transfer failed");
    }

    // Governance Functions
    function setPayableGovernanceShareholders(address payable[] memory addresses_,
    uint256[] memory shares_) public onlyPayableGovernanceSetter {
        require(_payableGovernanceAddresses.length == 0 
            && _payableGovernanceShares.length == 0, 
            "Payable Governance already set! To set again, reset first!");
        require(addresses_.length == shares_.length, 
            "Address and Shares length mismatch!");

        uint256 _totalShares;
        
        for (uint256 i = 0; i < addresses_.length; i++) {
            _totalShares += shares_[i];
            _payableGovernanceAddresses.push(addresses_[i]);
            _payableGovernanceShares.push(shares_[i]);
        }
        require(_totalShares == 1000, "Total Shares is not 1000!");
    }
    function resetPayableGovernanceShareholders() public onlyPayableGovernanceSetter {
        while (_payableGovernanceAddresses.length != 0) {
            _payableGovernanceAddresses.pop(); }
        while (_payableGovernanceShares.length != 0) {
            _payableGovernanceShares.pop(); }
    }

    // Governance View Functions
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    function payableGovernanceAddresses() public view 
    returns (address payable[] memory) {
        return _payableGovernanceAddresses;
    }
    function payableGovernanceShares() public view returns (uint256[] memory) {
        return _payableGovernanceShares;
    }

    // Withdraw Functions
    function withdrawEther() public onlyOwner {
        // require that there has been payable governance set.
        require(_payableGovernanceAddresses.length > 0 
            && _payableGovernanceShares.length > 0, 
            "Payable governance not set yet!");
         // this should never happen
        require(_payableGovernanceAddresses.length 
            == _payableGovernanceShares.length, 
            "Payable governance length mismatch!");
        
        // now, we check that the governance shares equal to 1000.
        uint256 _totalPayableShares;
        for (uint256 i = 0; i < _payableGovernanceShares.length; i++) {
            _totalPayableShares += _payableGovernanceShares[i]; }
        require(_totalPayableShares == 1000, "Payable Governance Shares is not 1000!");
        
        // // now, we start the withdrawal process if all conditionals pass
        // store current balance in local memory
        uint256 _totalETH = address(this).balance; 

        // withdraw loop for payable governance
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            uint256 _ethToWithdraw = ((_totalETH * _payableGovernanceShares[i]) / 1000);
            _withdraw(_payableGovernanceAddresses[i], _ethToWithdraw);
        }
    }

    function viewWithdrawAmounts() public view onlyOwner returns (uint256[] memory) {
        // require that there has been payable governance set.
        require(_payableGovernanceAddresses.length > 0 
            && _payableGovernanceShares.length > 0, 
            "Payable governance not set yet!");
         // this should never happen
        require(_payableGovernanceAddresses.length 
            == _payableGovernanceShares.length, 
            "Payable governance length mismatch!");
        
        // now, we check that the governance shares equal to 1000.
        uint256 _totalPayableShares;
        for (uint256 i = 0; i < _payableGovernanceShares.length; i++) {
            _totalPayableShares += _payableGovernanceShares[i]; }
        require(_totalPayableShares == 1000, "Payable Governance Shares is not 1000!");
        
        // // now, we start the array creation process if all conditionals pass
        // store current balance in local memory and instantiate array for input
        uint256 _totalETH = address(this).balance; 
        uint256[] memory _withdrawals = new uint256[] 
            (_payableGovernanceAddresses.length + 2);

        // array creation loop for payable governance values 
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            _withdrawals[i] = ( (_totalETH * _payableGovernanceShares[i]) / 1000 );
        }
        
        // push two last array spots as total eth and added eths of withdrawals
        _withdrawals[_payableGovernanceAddresses.length] = _totalETH;
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            _withdrawals[_payableGovernanceAddresses.length + 1] += _withdrawals[i]; }

        // return the final array data
        return _withdrawals;
    }

    // Shareholder Governance
    modifier onlyShareholder {
        bool _isShareholder;
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            if (msg.sender == _payableGovernanceAddresses[i]) {
                _isShareholder = true;
            }
        }
        require(_isShareholder, "You are not a shareholder!");
        _;
    }
    function unlockEmergencyFunctionsAsShareholder() public onlyShareholder {
        addressToEmergencyUnlocked[msg.sender] = true;
    }

    // Emergency Functions
    modifier onlyEmergency {
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            require(addressToEmergencyUnlocked[_payableGovernanceAddresses[i]],
                "Emergency Functions are not unlocked!");
        }
        _;
    }
    function emergencyWithdrawEther() public onlyOwner onlyEmergency {
        _withdraw(payable(msg.sender), address(this).balance);
    }

    // Proxy Padding
    bytes32[50] private proxyPadding;
}

///////////////////////////////////////////////////////
/////                Bucket Auction               /////
///////////////////////////////////////////////////////

interface iGasEvo {
    function mintAsController(address to_, uint256 amount_) external;
}

contract BucketAuction is Ownable {

    /** @dev Note: There is no ETH Withdrawal function here! Add it yourself! */ 

    /** @dev implementation: here is a basic withdrawal using Ownable
    
    function ownerWithdraw() external onlyOwner {
        _sendETH(payable(msg.sender), address(this).balance);
    }
    */

    // Interface and Constructor
    iGasEvo public GasEvo;
    constructor(address gasEvo_) { GasEvo = iGasEvo(gasEvo_); }
    function O_setGasEvo(address gasEvo_) external onlyOwner { 
        GasEvo = iGasEvo(gasEvo_); }

    // Events
    event Bid(address bidder, uint256 bidAmount, uint256 bidderTotal,
        uint256 bucketTotal);
    event FinalPriceSet(address setter, uint256 finalPrice);

    // Testing Events
    event RefundProcessed(address indexed bidder, uint256 refundAmount);
    event MintProcessed(address indexed bidder, uint256 mintAmount);
    
    // Fixed Configurations
    uint256 public immutable minCommit = 0.1 ether;

    // Global Variables
    uint256 public finalPrice;

    // Structs
    struct BidData {
        uint232 commitment;
        uint16 totalMinted;
        bool refundClaimed;
    }

    // Mappings
    mapping(address => BidData) public userToBidData;

    // Bool Triggers
    bool public biddingActive;

    // Administrative Functions
    function O_setBiddingActive(bool bool_) external onlyOwner { biddingActive = bool_; }
    function O_setFinalPrice(uint256 finalPrice_) external onlyOwner {
        require(!biddingActive, "Bidding is active!");
        finalPrice = finalPrice_;
        emit FinalPriceSet(msg.sender, finalPrice_);
    }
    // Administrative Process of Commits
    function O_processCommits(address[] calldata bidders_) external onlyOwner {
        _processCommits(bidders_);
    }

    // Internal Calculators
    function _calMintsFromCommitment(uint256 commitment_, uint256 finalPrice_)
    internal pure returns (uint256) {
        return commitment_ / finalPrice_;
    }
    function _calRemainderFromCommitment(uint256 commitment_, uint256 finalPrice_)
    internal pure returns (uint256) {
        return commitment_ % finalPrice_;
    }

    // Internal Processing 
    function _sendETH(address to_, uint256 amount_) internal {
        (bool success, ) = to_.call{value: amount_}("");
        require(success, "Transfer failed");
    }

    /** @dev edgeCases:
     *  Case 1: Refunds fail, breaking the processing
     *  Solution 1: OwnerMint NFTs + Manual Refund after all processing has finished
     *  
     *  Case 2: Mints fail, breaking the processing
     *  Solution 2: OwnerMint NFTs + Manual Refund after all processing has finished
     * 
     *  Case 3: Reentrancy on _internalProcessRefund
     *  Solution 3: CEI of setting refundClaimed will break the reentrancy attack
     *
     *  Case 4: Reentrancy on _internalProcessMint
     *  Solution 4: CEI of setting totalMinted will break the reentrancy attack
     *              but even better, just use a normal _mint instead of _safeMint
    */
    function _internalProcessRefund(address bidder_, uint256 refundAmount_) internal {
        userToBidData[bidder_].refundClaimed = true;
        if (refundAmount_ != 0) { _sendETH(bidder_, refundAmount_); }
        emit RefundProcessed(bidder_, refundAmount_);
    }
    function _internalProcessMint(address bidder_, uint256 mintAmount_) internal {
        uint16 _mintAmount = uint16(mintAmount_);
        userToBidData[bidder_].totalMinted += _mintAmount;
        /** @dev implementation:
         *  minting code goes here
        */
        GasEvo.mintAsController(bidder_, mintAmount_);

        emit MintProcessed(bidder_, mintAmount_);
    }
    function _internalProcessCommit(address bidder_, uint256 finalPrice_) internal {
        BidData memory _BidData = userToBidData[bidder_];
        uint256 _commitment = uint256(_BidData.commitment);
        uint256 _eligibleRefunds = _calRemainderFromCommitment(_commitment, finalPrice_);
        uint256 _eligibleMints = _calMintsFromCommitment(_commitment, finalPrice_);

        if (!_BidData.refundClaimed) {
            _internalProcessRefund(bidder_, _eligibleRefunds);
        }

        if (_eligibleMints > _BidData.totalMinted) {
            uint256 _remainingMints = _eligibleMints - _BidData.totalMinted;
            _internalProcessMint(bidder_, _remainingMints);
        }
    }
    function _processCommits(address[] calldata bidders_) internal {
        uint256 _finalPrice = finalPrice;
        require(_finalPrice != 0, "Final Price not set!");
        for (uint256 i; i < bidders_.length;) {
            _internalProcessCommit(bidders_[i], _finalPrice);
            unchecked { ++i; }
        }
    }

    // Public Bidding Function
    function bid() public virtual payable {
        // Require bidding to be active
        require(biddingActive, "Bidding is not active!");
        // Require EOA only
        require(msg.sender == tx.origin, "No Smart Contracts!");
        // Modulus for Cleaner Bids
        require(msg.value % 1000000000000000 == 0, 
            "Please bid with a minimum decimal of 0.001 ETH!");
        require(msg.value > 0, 
            "Please bid with msg.value!");
        
        // Load the current commitment value from mapping to memory
        uint256 _currentCommitment = userToBidData[msg.sender].commitment;
        
        // Calculate thew new commitment based on the bid
        uint256 _newCommitment = _currentCommitment + msg.value;

        // Make sure the new commitment is higher than the minimum commitment
        require(_newCommitment >= minCommit, "Commitment below minimum!");

        // Store the new commitment value
        userToBidData[msg.sender].commitment = uint232(_newCommitment);

        // Emit Event for Data Parsing and Analysis
        emit Bid(msg.sender, msg.value, _newCommitment, address(this).balance);
    }

    // Public View Functions
    function getEligibleMints(address bidder_) public view returns (uint256) {
        require(finalPrice != 0, "Final Price not set!");

        uint256 _eligibleMints = _calMintsFromCommitment(
            userToBidData[bidder_].commitment, finalPrice);
        uint256 _alreadyMinted = userToBidData[bidder_].totalMinted;

        return (_eligibleMints - _alreadyMinted);
    }
    function getRefundAmount(address bidder_) public view returns (uint256) {
        require(finalPrice != 0, "Final Price not set!");

        uint256 _remainder = _calRemainderFromCommitment(
            userToBidData[bidder_].commitment, finalPrice);
        
        return !userToBidData[bidder_].refundClaimed ? _remainder : 0;
    }
    function queryCommitments(address[] calldata bidders_) external 
    view returns (BidData[] memory) {
        uint256 l = bidders_.length;
        BidData[] memory _BidDatas = new BidData[] (l);
        for (uint256 i; i < l;) {
            _BidDatas[i] = userToBidData[bidders_[i]];
            unchecked { ++i; }
        }
        return _BidDatas;
    }

    // Proxy Padding
    bytes32[50] private proxyPadding;
}

///////////////////////////////////////////////////////
/////                 ERC1155-Like                /////
///////////////////////////////////////////////////////

interface ERC1155TokenReceiver {
    function onERC1155Received(address operator_, address from_, uint256 id_,
        uint256 amount_, bytes calldata data_) external returns (bytes4);
    function onERC1155BatchReceived(address operator_, address from_,
        uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_)
        external returns (bytes4);
}

abstract contract GoldSaucerChip is Ownable {
    
    // Events
    event TransferSingle(address indexed operator_, address indexed from_, 
    address indexed to_, uint256 id_, uint256 amount_);
    event TransferBatch(address indexed operator_, address indexed from_, 
    address indexed to_, uint256[] ids_, uint256[] amounts_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, 
    bool approved_);
    event URI(string value_, uint256 indexed id_);

    // Mappings

    // mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // Base Info
    string public name; 
    string public symbol; 

    // Setting Name and Symbol (Missing in ERC1155 Generally)
    constructor(string memory name_, string memory symbol_) {
        name = name_; 
        symbol = symbol_; 
    }

    function balanceOf(address owner_, uint256 id_) public view virtual returns (uint256) {
        /** @dev implementation:
         *  we override this into the parent contract
         */
        // // We only return a phantom balance using ID 1
        // if (id_ != 1) return 0;
        // return userToBidData[owner_].commitment > 0 ? 1 : 0;
    }

    function balanceOfBatch(address[] memory addresses_, uint256[] memory ids_) 
    public virtual view returns (uint256[] memory) {
        require(addresses_.length == ids_.length,
            "ERC1155: accounts and ids length mismatch!");
        uint256[] memory _balances = new uint256[](addresses_.length);
        for (uint256 i = 0; i < addresses_.length; i++) {
            _balances[i] = balanceOf(addresses_[i], ids_[i]);
        }
        return _balances;
    }
    
    // URI Display Type Setting (Default to ERC721 Style)
        // 1 - ERC1155 Style
        // 2 - ERC721 Style
        // 3 - Mapping Style
    uint256 public URIType = 2; 
    function _setURIType(uint256 uriType_) internal virtual {
        URIType = uriType_;
    }
    function O_setURIType(uint256 uriType_) external onlyOwner {
        _setURIType(uriType_);
    }

    // ERC1155 URI
    string public _uri;
    function _setURI(string memory uri_) internal virtual { _uri = uri_; }
    function O_setURI(string calldata uri_) external onlyOwner { _setURI(uri_); }
    
    // ERC721 URI (Override)
    string internal baseTokenURI; 
    string internal baseTokenURI_EXT;

    function _setBaseTokenURI(string memory uri_) internal virtual { 
        baseTokenURI = uri_; }
    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_; }
    function O_setBaseTokenURI(string calldata uri_) external onlyOwner {
        _setBaseTokenURI(uri_); }
    function O_setBaseTokenURI_EXT(string calldata ext_) external onlyOwner {
        _setBaseTokenURI_EXT(ext_); }
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
            48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Mapping Style URI (Override)
    mapping(uint256 => string) public tokenIdToURI;
    
    function _setURIOfToken(uint256 id_, string memory uri_) internal virtual {
        tokenIdToURI[id_] = uri_; }
    function O_setURIOfToken(uint256 id_, string calldata uri_) external onlyOwner {
        _setURIOfToken(id_, uri_); }


    // URI (0xInuarashi Version)
    function uri(uint256 id_) public virtual view returns (string memory) {
        // ERC1155
        if (URIType == 1) return _uri;
        // ERC721
        else if (URIType == 2) return 
            string(abi.encodePacked(baseTokenURI, _toString(id_), baseTokenURI_EXT));
        // Mapping 
        else if (URIType == 3) return tokenIdToURI[id_];
        else return "";
    }
    function tokenURI(uint256 id_) public virtual view returns (string memory) {
        return uri(id_);
    }

    // Internal Logics
    function _isSameLength(uint256 a, uint256 b) internal pure returns (bool) {
        return a == b;
    }
    function _isApprovedOrOwner(address from_) internal view returns (bool) {
        return msg.sender == from_ 
            || isApprovedForAll[from_][msg.sender];
    }
    function _ERC1155Supported(address from_, address to_, uint256 id_,
    uint256 amount_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) :
            ERC1155TokenReceiver(to_).onERC1155Received(
                msg.sender, from_, id_, amount_, data_) ==
            ERC1155TokenReceiver.onERC1155Received.selector,
                "_ERC1155Supported(): Unsupported Recipient!"
        );
    }
    function _ERC1155BatchSupported(address from_, address to_, uint256[] memory ids_,
    uint256[] memory amounts_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) :
            ERC1155TokenReceiver(to_).onERC1155BatchReceived(
                msg.sender, from_, ids_, amounts_, data_) ==
            ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "_ERC1155BatchSupported(): Unsupported Recipient!"
        );
    }

    // ERC1155 Logics
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        // isApprovedForAll[msg.sender][operator_] = approved_;
        // emit ApprovalForAll(msg.sender, operator_, approved_);

        require(!approved_, "SBT: Soulbound");
        require(operator_ == address(0), "SBT: Soulbound");
    }

    function safeTransferFrom(address from_, address to_, uint256 id_, 
    uint256 amount_, bytes memory data_) public virtual {
        // require(_isApprovedOrOwner(from_));
        
        // balanceOf[from_][id_] -= amount_;
        // balanceOf[to_][id_] += amount_;

        // emit TransferSingle(msg.sender, from_, to_, id_, amount_);

        // _ERC1155Supported(from_, to_, id_, amount_, data_);

        require(amount_ == 0, "SBT: Soulbound");
        require(from_ == address(0), "SBT: Soulbound");
        require(to_ == address(0), "SBT: Soulbound");
        require(id_ == 0, "SBT: Soulbound");
        require(data_.length == 0, "SBT: Soulbound");
    }
    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_,
    uint256[] memory amounts_, bytes memory data_) public virtual {
        // require(_isSameLength(ids_.length, amounts_.length));
        // require(_isApprovedOrOwner(from_));

        // for (uint256 i = 0; i < ids_.length; i++) {
        //     balanceOf[from_][ids_[i]] -= amounts_[i];
        //     balanceOf[to_][ids_[i]] += amounts_[i];
        // }

        // emit TransferBatch(msg.sender, from_, to_, ids_, amounts_);

        // _ERC1155BatchSupported(from_, to_, ids_, amounts_, data_);

        require(amounts_.length == 0, "SBT: Soulbound");
        require(from_ == address(0), "SBT: Soulbound");
        require(to_ == address(0), "SBT: Soulbound");
        require(ids_.length == 0, "SBT: Soulbound");
        require(data_.length == 0, "SBT: Soulbound");
    }

    // Phantom Mint
    function _phantomMintGoldSaucerChip(address to_) internal {
        emit TransferSingle(msg.sender, address(0), to_, 1, 1);
        
        // we dont need to make this callback as we're just emitting an event
        // _ERC1155Supported(address(0), to_, 1, 1, ""); 
    }

    // ERC165 Logic
    function supportsInterface(bytes4 interfaceId_) public pure virtual returns (bool) {
        return 
        interfaceId_ == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId_ == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
        interfaceId_ == 0x0e89341c;   // ERC165 Interface ID for ERC1155MetadataURI
    }

    // Proxy Padding
    bytes32[50] private proxyPadding;
}

///////////////////////////////////////////////////////
/////             MerkleAllowlistAmount           /////
///////////////////////////////////////////////////////

abstract contract MerkleAllowlistAmount {
    bytes32 internal _merkleRoot;
    function _setMerkleRoot(bytes32 merkleRoot_) internal virtual {
        _merkleRoot = merkleRoot_;
    }
    function isAllowlisted(address address_, bytes32[] memory proof_,
    uint256 amount_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_, amount_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i] ? 
            keccak256(abi.encodePacked(_leaf, proof_[i])) : 
            keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merkleRoot;
    }
}

contract GoldSaucerAuction is Ownable, PayableGovernance,
BucketAuction, GoldSaucerChip, MerkleAllowlistAmount {

    // Constructor to set the name, symbol, and gasEvo address
    constructor(address gasEvo_) 
    GoldSaucerChip("Gold Saucer Chip", "GSCHIP") 
    BucketAuction(gasEvo_)
    {}
    
    // Overrides of Functions (ERC1155 / GoldSaucerChip)
    function balanceOf(address owner_, uint256 id_) public view override returns (uint256) {
        // We only return a phantom balance using ID 1
        if (id_ != 1) return 0;
        return  userToBidData[owner_].commitment > 0 ? 1 :
                addressToAllowlistMinted[owner_] > 0 ? 1 : 0;
    }

    // Overrides of Functions (BucketAuction)
    function bid() public override payable {
        BucketAuction.bid();
    }

    // Allowlist 
    event GangMint(address indexed minter, uint256 mintAmount, 
        uint256 newTotalMintAmount, uint256 proofMintAmount);
    
    uint256 public totalAllowlistsMinted;
    uint256 public allowlistMintPrice;
    bool public allowlistMintEnabled;
    
    mapping(address => uint256) public addressToAllowlistMinted;

    function O_setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _setMerkleRoot(merkleRoot_); }
    function O_setAllowListMintEnabled(bool bool_) external onlyOwner {
        allowlistMintEnabled = bool_; }
    function O_setAllowlistMintPrice(uint256 price_) external onlyOwner {
        allowlistMintPrice = price_; }

    function gangMint(uint256 mintAmount_, bytes32[] calldata proof_, 
    uint256 proofMintAmount_) external payable {
        // AllowlistMint must be enabled
        require(allowlistMintEnabled, "Gang Mint not enabled yet!");
        // Allowlist price must be over 0
        require(allowlistMintPrice != 0, "Allowlist price not set!");
        // No smart contracts
        require(msg.sender == tx.origin, "No Smart Contracts!");
        // Merkleproof Checking
        require(isAllowlisted(msg.sender, proof_, proofMintAmount_),
            "You are not allowlisted for this amount!");
        
        // Eligible Amount Checking
        uint256 _alreadyMinted = addressToAllowlistMinted[msg.sender];
        uint256 _requestedMint = mintAmount_;
        uint256 _newTotalMint = _alreadyMinted + _requestedMint;
        require(proofMintAmount_ >= _newTotalMint, "Not enough mints remaining!");

        // Pricing Calculation and Checking
        uint256 _bidRemainders = getRefundAmount(msg.sender);
        uint256 _totalMintCost = allowlistMintPrice * _requestedMint;

        if (_bidRemainders > _totalMintCost) {
            userToBidData[msg.sender].commitment -= uint232(_totalMintCost);
        }

        else {
            require(_totalMintCost == (_bidRemainders + msg.value),
                "Invalid value sent!");

            if (_bidRemainders != 0) {
                userToBidData[msg.sender].refundClaimed = true;
            }
        }

        // Add requestedMint to addressToAllowlistMinted tracker
        addressToAllowlistMinted[msg.sender] += _requestedMint;

        // Emit the Mint event
        emit GangMint(msg.sender, _requestedMint, _newTotalMint, proofMintAmount_);
    }

    // Initialize Chips
    function initializeGoldSaucerChips(address[] calldata addresses_) 
    external onlyOwner {
        uint256 l = addresses_.length;
        for (uint256 i; i < l;) {
            _phantomMintGoldSaucerChip(addresses_[i]);
            unchecked{++i;}
        }    
    }

    // Front-End Function
    function getMintPriceForUser(address minter_, uint256 mintAmount_) public view 
    returns (uint256) {
        uint256 _refundAmount = getRefundAmount(minter_);
        uint256 _totalPrice = allowlistMintPrice * mintAmount_;
        return (_refundAmount >= _totalPrice) ? 
        0 :
        (_totalPrice - _refundAmount);
    }

    // Proxy Padding
    // bytes32[50] private proxyPadding;

}