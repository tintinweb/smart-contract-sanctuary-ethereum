/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC3475 {
    // STRUCTURE 
    /**
     * @dev Values structure of the Metadata
     */
    struct Values { 
        string stringValue;
        uint uintValue;
        address addressValue;
        bool boolValue;
        string[] stringArryValue;
        uint[] uintArryValue;
        address[] addressArryValue;
        bool[] boolArryValue;
    }
    /**
     * @dev structure allows to define particular bond metadata (ie the values in the class as well as nonce inputs). 
     * @notice 'title' defining the title information,
     * @notice '_type' explaining the data type of the title information added (eg int, bool, address),
     * @notice 'description' explains little description about the information stored in the bond",
     */
    struct Metadata {
        string title;
        string _type;
        string description;
    }
    /**
     * @dev structure that defines the parameters for specific issuance of bonds and amount which are to be transferred/issued/given allowance, etc.
     * @notice this structure is used to streamline the input parameters for functions of this standard with that of other Token standards like ERC20.
     * @classId is the class id of the bond.
     * @nonceId is the nonce id of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @amount is the amount of the bond that will be transferred.
     */
    struct Transaction {
        uint256 classId;
        uint256 nonceId;
        uint256 amount;
    }

    // WRITABLES
    /**
     * @dev allows the transfer of a bond from one address to another (either single or in batches).
     * @param _from is the address of the holder whose balance is about to decrease.
     * @param _to is the address of the recipient whose balance is about to increase.
     * @param _transactions is the object defining {class,nonce and amount of the bonds to be transferred}.
     */
    function transferFrom(address _from, address _to, Transaction[] calldata _transactions) external;
    /**
     * @dev allows the transfer of allowance from one address to another (either single or in batches).
     * @param _from is the address of the holder whose balance about to decrease.
     * @param _to is the address of the recipient whose balance is about to increased.
     * @param _transactions is the object defining {class,nonce and amount of the bonds to be allowed to transferred}.
     */
    function transferAllowanceFrom(address _from, address _to, Transaction[] calldata _transactions) external;
    /**
     * @dev allows issuing of any number of bond types to an address(either single/batched issuance).
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param _to is the address to which the bond will be issued.
     * @param _transactions is the object defining {class,nonce and amount of the bonds to be issued for given whitelisted bond}.
     */
    function issue(address _to, Transaction[] calldata _transactions) external;
    /**
     * @dev allows redemption of any number of bond types from an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param _from is the address _from which the bond will be redeemed.
     * @param _transactions is the object defining {class,nonce and amount of the bonds to be redeemed for given whitelisted bond}.
     */
    function redeem(address _from, Transaction[] calldata _transactions) external;
    
    /**
     * @dev allows the transfer of any number of bond types from an address to another.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param _from is the address of the holder whose balance about to decrees.
     * @param _transactions is the object defining {class,nonce and amount of the bonds to be redeemed for given whitelisted bond}.
     */
    function burn(address _from, Transaction[] calldata _transactions) external;
    
    /**
     * @dev Allows _spender to withdraw from your account multiple times, up to the amount.
     * @notice If this function is called again, it overwrites the current allowance with amount.
     * @param _spender is the address the caller approve for his bonds.
     * @param _transactions is the object defining {class,nonce and amount of the bonds to be approved for given whitelisted bond}.
     */
    function approve(address _spender, Transaction[] calldata _transactions) external;
    
    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     * @dev MUST emit the ApprovalForAll event on success.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved "True" if the operator is approved, "False" to revoke approval.
     */
    function setApprovalFor(address _operator, bool _approved) external;
    
    // READABLES 
    
    /**
     * @dev Returns the total supply of the bond in question.
     */
    function totalSupply(uint256 classId, uint256 nonceId) external view returns (uint256);
    
    /**
     * @dev Returns the redeemed supply of the bond in question.
     */
    function redeemedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);
    
    /**
     * @dev Returns the active supply of the bond in question.
     */
    function activeSupply(uint256 classId, uint256 nonceId) external view returns (uint256);
    
    /**
     * @dev Returns the burned supply of the bond in question.
     */
    function burnedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);
    
    /**
     * @dev Returns the balance of the giving bond classId and bond nonce.
     */
    function balanceOf(address _account, uint256 classId, uint256 nonceId) external view returns (uint256);
    
    /**
     * @dev Returns the JSON metadata of the classes.
     * The metadata SHOULD follow a set of structure explained later in eip-3475.md
     * @param metadataId is the index corresponding to the class parameter that you want to return from mapping.
     */
    function classMetadata(uint256 metadataId) external view returns ( Metadata memory);
    
    /**
     * @dev Returns the JSON metadata of the Values of the nonces in the corresponding class.
     * @param classId is the specific classId of which you want to find the metadata of the corresponding nonce.
     * @param metadataId is the index corresponding to the class parameter that you want to return from mapping.
     * @notice The metadata SHOULD follow a set of structure explained later in metadata section.
     */
    function nonceMetadata(uint256 classId, uint256 metadataId) external view returns ( Metadata memory);
    
    /**
     * @dev Returns the values of the given classId.
     * @param classId is the specific classId of which we want to return the parameter.
     * @param metadataId is the index corresponding to the class parameter that you want to return from mapping.
     * the metadata SHOULD follow a set of structures explained in eip-3475.md
     */
    function classValues(uint256 classId, uint256 metadataId) external view returns ( Values memory);
   
    /**
     * @dev Returns the values of given nonceId.
     * @param metadataId index number of structure as explained in the metadata section in EIP-3475.
     * @param classId is the class of bonds for which you determine the nonce.
     * @param nonceId is the nonce for which you return the value struct info.
     * Returns the values object corresponding to the given value.
     */
    function nonceValues(uint256 classId, uint256 nonceId, uint256 metadataId) external view returns ( Values memory);
    
    /**
     * @dev Returns the information about the progress needed to redeem the bond identified by classId and nonceId.
     * @notice Every bond contract can have its own logic concerning the progress definition.
     * @param classId The class of bonds.
     * @param nonceId is the nonce of bonds for finding the progress.
     * Returns progressAchieved is the current progress achieved.
     * Returns progressRemaining is the remaining progress.
     */
    function getProgress(uint256 classId, uint256 nonceId) external view returns (uint256 progressAchieved, uint256 progressRemaining);
   
    /**
     * @notice Returns the amount that spender is still allowed to withdraw from _owner (for given classId and nonceId issuance)
     * @param _owner is the address whose owner allocates some amount to the _spender address.
     * @param classId is the classId of the bond.
     * @param nonceId is the nonce corresponding to the class for which you are approving the spending of total amount of bonds.
     */
    function allowance(address _owner, address _spender, uint256 classId, uint256 nonceId) external view returns (uint256);
    /**
     * @notice Queries the approval status of an operator for bonds (for all classes and nonce issuances of owner).
     * @param _owner is the current holder of the bonds for all classes/nonces.
     * @param _operator is the address with access to the bonds of _owner for transferring. 
     * Returns "true" if the operator is approved, "false" if not.
     */
    function isApprovedFor(address _owner, address _operator) external view returns (bool);

    // EVENTS
    /**
     * @notice MUST trigger when tokens are transferred, including zero value transfers.
     */
    event Transfer(address indexed _operator, address indexed _from, address indexed _to, Transaction[] _transactions);
    /**
     * @notice MUST trigger when tokens are issued
     */
    event Issue(address indexed _operator, address indexed _to, Transaction[] _transactions);
    /**
     * @notice MUST trigger when tokens are redeemed
     */
    event Redeem(address indexed _operator, address indexed _from, Transaction[] _transactions);
    /**
     * @notice MUST trigger when tokens are burned
     */
    event Burn(address indexed _operator, address indexed _from, Transaction[] _transactions);
    /**
     * @dev MUST emit when approval for a second party/operator address to manage all bonds from a classId given for an owner address is enabled or disabled (absence of an event assumes disabled).
     */
    event ApprovalFor(address indexed _owner, address indexed _operator, bool _approved);
}

contract ERC3475 is IERC3475 {
    struct Class {
        uint256 classId;
        uint256 liquidity;
        mapping(uint256 => Values) values;
    }

    struct Nonce {
        uint256 nonceId;
        mapping(uint256 => Values) values;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private _balances;
    mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => uint256)))) private _allowances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => mapping(uint256 => uint256)) private _activeSupply;
    mapping(uint256 => mapping(uint256 => uint256)) private _burnedSupply;
    mapping(uint256 => mapping(uint256 => uint256)) private _redeemedSupply;
    mapping(uint256 => IERC3475.Metadata) internal _classMetadata;
    mapping(uint256 => mapping(uint256 => IERC3475.Metadata)) private _nonceMetadata;
    mapping(uint256 => mapping(uint256 => Values)) private _classValues;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Values))) private _nonceValues;
    mapping(uint256 => Class) public classes;
    mapping(address => mapping(uint256 => mapping(uint256 => Nonce))) public nonces;

    function transferFrom(address _from, address _to, Transaction[] calldata _transactions) public virtual override {
        require(_from != address(0), "ERC3475: can't transfer allowance from zero address");
        require(_to != address(0), "ERC3475: can't transfer to from zero address");
        require(msg.sender == _from || isApprovedFor(_from, msg.sender), "ERC3475: neither owner or approved");

        for(uint256 i = 0; i < _transactions.length; i++) {
            _transferFrom(_from, _to, _transactions[i]);
        }

        emit Transfer(msg.sender, _from, _to, _transactions);
    }

    function transferAllowanceFrom(address _from, address _to, Transaction[] calldata _transactions) public virtual override {
        require(_from != address(0), "ERC3475: can't transfer allowance from zero address");
        require(_to != address(0), "ERC3475: can't transfer allowance to zero address");

        uint256 len = _transactions.length;

        for(uint256 i = 0; i < len; i++) {
            require(
                _transactions[i].amount <= _allowances[_from][msg.sender][_transactions[i].classId][_transactions[i].nonceId],
                "ERC3475: not owner or approved"
            );
            _transferAllowanceFrom(msg.sender, _from, _to, _transactions[i]);
        }

        emit Transfer(msg.sender, _from, _to, _transactions);
    }
    
    function issue(address _to, Transaction[] calldata _transactions) public virtual override {
        require(_to != address(0), "ERC3475: can't issue to zero address");

        for(uint256 i = 0; i < _transactions.length; i++) {
            _issue(_to, _transactions[i]);
        }

        emit Issue(msg.sender, _to, _transactions);
    }

    function redeem(address _from, Transaction[] calldata _transactions) public virtual override {
        require(_from != address(0), "ERC3475: can't redeem from zero address");

        for(uint256 i = 0; i < _transactions.length; i++) {
            (, uint256 progressRemaining) = getProgress(_transactions[i].classId, _transactions[i].nonceId);
            require(progressRemaining == 0, "ERC3475: not redeemable");

            _redeem(_from, _transactions[i]);
        }

        emit Redeem(msg.sender, _from, _transactions);
    }

    function burn(address _from, Transaction[] calldata _transactions) public virtual override {
        require(_from != address(0), "ERC3475: can't burn from zero address");
        require(msg.sender == _from || isApprovedFor(_from, msg.sender), "ERC3475: not owner or approved");

        for(uint256 i = 0; i < _transactions.length; i++) {
            _burn(_from, _transactions[i]);
        }

        emit Burn(msg.sender, _from, _transactions);
    }

    function approve(address _spender, Transaction[] calldata _transactions) public virtual override {
        for(uint256 i = 0; i < _transactions.length; i++) {
            _allowances[msg.sender][_spender][_transactions[i].classId][_transactions[i].nonceId] = _transactions[i].amount;
        }
    }

    function setApprovalFor(address _operator, bool _approved) public virtual override {
        _operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalFor(msg.sender, _operator, _approved);
    }

    function redeemedSupply(uint256 _classId, uint256 _nonceId) public view override returns (uint256) {
        return _redeemedSupply[_classId][_nonceId];
    }

    function activeSupply(uint256 _classId, uint256 _nonceId) public view override returns (uint256) {
        return _activeSupply[_classId][_nonceId];
    }

    function burnedSupply(uint256 _classId, uint256 _nonceId) public view override returns (uint256) {
        return _burnedSupply[_classId][_nonceId];
    }

    function totalSupply(uint256 _classId, uint256 _nonceId) public view override returns (uint256) {
        return (
            _activeSupply[_classId][_nonceId] +
            _burnedSupply[_classId][_nonceId] +
            _redeemedSupply[_classId][_nonceId]
        );
    }

    function balanceOf(address _account, uint256 _classId, uint256 _nonceId) public view override returns (uint256) {
        return _balances[_account][_classId][_nonceId];
    }

    function allowance(address _owner, address _spender, uint256 _classId, uint256 _nonceId) public view override returns (uint256) {
        return _allowances[_owner][_spender][_classId][_nonceId];
    }

    function classMetadata(uint256 _metadataId) public view override returns (Metadata memory) {
        return _classMetadata[_metadataId];
    }

    function nonceMetadata(uint256 _classId, uint256 _metadataId) public view override returns (Metadata memory) {
        return _nonceMetadata[_classId][_metadataId];
    }

    function classValues(uint256 _classId, uint256 _metadataId) public view override returns (Values memory) {
        return _classValues[_classId][_metadataId];
    }

    function nonceValues(uint256 _classId, uint256 _nonceId, uint256 _metadataId) public view override returns (Values memory) {
        return _nonceValues[_classId][_nonceId][_metadataId];
    }

    function isApprovedFor(address _owner, address _operator) public view override returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function getProgress(uint256 _classId, uint256 _nonceId) public view override returns (uint256 progressAchieved, uint256 progressRemaining) {
        uint256 issuanceDate = nonces[msg.sender][_classId][_nonceId].values[0].uintValue;
        uint256 maturityDate = nonces[msg.sender][_classId][_nonceId].values[1].uintValue;

        progressAchieved = block.timestamp - issuanceDate;
        progressRemaining = block.timestamp < maturityDate ?
            maturityDate - block.timestamp
        :
            0;
    }

    function getClassLiquidity(uint256 _classId) public view returns(uint256) {
        return classes[_classId].liquidity;
    }

    function getClassValue(
        uint256 _classId,
        uint256 _metadataId
    ) public view returns(Values memory) {
        return classes[_classId].values[_metadataId];
    }

    function getNonceValue(
        address _investor,
        uint256 _classId,
        uint256 _nonceId,
        uint256 _metadataId
    ) public view returns(Values memory) {
        return nonces[_investor][_classId][_nonceId].values[_metadataId];
    }

    function nonceExists(
        uint256 _nonceId,
        address _investor,
        uint256 _classId
    ) public view returns(bool) {
        return nonces[_investor][_classId][_nonceId].nonceId != 0;
    }

    function _transferFrom(address _from, address _to, Transaction memory _transaction) private {
        require(
            _balances[_from][_transaction.classId][_transaction.nonceId] >= _transaction.amount,
            "ERC3475: not enough bonds"
        );

        _balances[_from][_transaction.classId][_transaction.nonceId] -= _transaction.amount;
        _balances[_to][_transaction.classId][_transaction.nonceId] += _transaction.amount;
    }

    function _transferAllowanceFrom(address _operator, address _from, address _to, Transaction calldata _transaction) private {
        require(
            _balances[_from][_transaction.classId][_transaction.nonceId] >= _transaction.amount,
            "ERC3475: not enough bonds"
        );

        _allowances[_from][_operator][_transaction.classId][_transaction.nonceId] -= _transaction.amount;
        _balances[_from][_transaction.classId][_transaction.nonceId] -= _transaction.amount;
        _balances[_to][_transaction.classId][_transaction.nonceId] += _transaction.amount;
    }

    function _issue(address _to, Transaction memory _transaction) internal {
        _balances[_to][_transaction.classId][_transaction.nonceId] += _transaction.amount;
        _activeSupply[_transaction.classId][_transaction.nonceId] += _transaction.amount;
    }

    function _redeem(address _from, Transaction memory _transaction) private {
        require(
            _balances[_from][_transaction.classId][_transaction.nonceId] >= _transaction.amount,
            "ERC3475: not enough bonds"
        );

        _balances[_from][_transaction.classId][_transaction.nonceId] -= _transaction.amount;
        _activeSupply[_transaction.classId][_transaction.nonceId] -= _transaction.amount;
        _redeemedSupply[_transaction.classId][_transaction.nonceId] += _transaction.amount;
    }

    function _burn(address _from, Transaction calldata _transaction) private {
        require(
            _balances[_from][_transaction.classId][_transaction.nonceId] >= _transaction.amount,
            "ERC3475: not enough bonds"
        );

        _balances[_from][_transaction.classId][_transaction.nonceId] -= _transaction.amount;
        _activeSupply[_transaction.classId][_transaction.nonceId] -= _transaction.amount;
        _burnedSupply[_transaction.classId][_transaction.nonceId] += _transaction.amount;
    }
}

contract Token is ERC3475 {
    uint256 public lastAvailableClass;
    uint256[] public classMetadataIds;

    address publisher;

    struct Data {
        string doi;
        address author;
        uint256 price;
        uint256 dataPrice;
        uint256 algorithmPrice;
        address currency;
        address[] coAuthors;
        uint256 uploadTime;
        string[] sponsors;
        string[] affiliations;
        string domain;
        string subdomain;
        string introduction;
        string[] keywords;
        string[] licenses;
        string filename;
        string fileHash;
        string fileTitle;
        string fileType;
        string fileFormat;
        string[] references;
        uint256 version;
        string uri;
    }

    modifier onlyPublisher{
        require(msg.sender == publisher, "ERC3475Minteer: permission denied");
        _;
    }

    constructor() {
        publisher = msg.sender;

        _classMetadata[0].title = "nonce property";
        _classMetadata[0]._type = "string";
        _classMetadata[0].description = "utilities of the token nonces under all the token class";

        classes[0].values[0].stringValue = "{0: ownership, 1: manuscript access, 2: data access, 3: algorithm access}";
    }

    /** 
    * @notice publish the paper and mint the ownership tokens to author and co-authors
    * @param _inputValues class metadata values that defines the paper
    */
    function publishPaper(
        uint256[] memory _amount,
        Data memory _inputValues
    ) public onlyPublisher {
        lastAvailableClass++;
        uint256 newClassId = lastAvailableClass;

        _mintOwnershipTokens(newClassId, _amount, _inputValues);   
    }

    function issueAccessToken(Transaction memory _transaction) public {
        uint256 classId = _transaction.classId;
        uint256 nonceId = _transaction.nonceId;

        require(classId != 0, "ERC3475Minter: invalid class id");
        require(nonceId >= 1 && nonceId <= 3, "Token: invalid access type");

        uint256 balance = balanceOf(msg.sender, classId, nonceId);
        require(balance == 0, "Token: you already have access right");
 
        _issue(msg.sender, _transaction);
    }

    function _mintOwnershipTokens(
        uint256 _classId,
        uint256[] memory _amounts,
        Data memory _inputValues
    ) private {
        require(_amounts.length == _inputValues.coAuthors.length + 1, "Token: invalid length for _amount");

        Class storage class = classes[_classId];
        class.classId = _classId;

        class.values[0].stringValue = _inputValues.doi;
        class.values[1].addressValue = _inputValues.author;
        class.values[2].uintValue = _inputValues.price;
        class.values[3].uintValue = _inputValues.dataPrice;
        class.values[4].uintValue = _inputValues.algorithmPrice;
        class.values[5].addressValue = _inputValues.currency;
        class.values[6].addressArryValue = _inputValues.coAuthors;
        class.values[7].uintValue = block.timestamp;
        class.values[8].stringArryValue = _inputValues.sponsors;
        class.values[9].stringArryValue = _inputValues.affiliations;
        class.values[10].stringValue = _inputValues.domain;
        class.values[11].stringValue = _inputValues.subdomain;
        class.values[12].stringValue = _inputValues.introduction;
        class.values[13].stringArryValue = _inputValues.keywords;
        class.values[14].stringArryValue = _inputValues.licenses;
        class.values[15].stringValue = _inputValues.filename;
        class.values[16].stringValue = _inputValues.fileHash;
        class.values[17].stringValue = _inputValues.fileTitle;
        class.values[18].stringValue = _inputValues.fileType;
        class.values[19].stringValue = _inputValues.fileFormat;
        class.values[20].stringArryValue = _inputValues.references;
        class.values[21].uintValue = _inputValues.version;
        class.values[22].stringValue = _inputValues.uri;

        address author = _inputValues.author;
        address[] memory coAuthors = _inputValues.coAuthors;

        require(author != address(0), "ERC3475Minter: cannot mint token to zero address");

        Transaction memory transaction;
        transaction.amount = _amounts[0];
        transaction.classId = _classId;
        transaction.nonceId = 0;
        
        _issue(author, transaction);

        // mint the ownership tokens to co-authors
        for(uint256 i = 0; i < coAuthors.length; i++) {
            require(coAuthors[i] != address(0), "ERC3475Minter: cannot mint token to zero address");

            Transaction memory _transaction;
            _transaction.amount = _amounts[i+1];
            _transaction.classId = _classId;
            _transaction.nonceId = 0;

            _issue(coAuthors[i], _transaction);
        }
    }

    function checkAccess(address _viewer, uint256 _classeID) public view returns(bool[3] memory _access){
        if(balanceOf(_viewer, _classeID, 1) != 0 || classes[_classeID].values[1102].uintValue == 0) _access[0] = true;

        if(balanceOf(_viewer, _classeID, 2) != 0 || classes[_classeID].values[1125].uintValue == 0) _access[1] = true;

        if(balanceOf(_viewer, _classeID, 3) != 0 || classes[_classeID].values[1126].uintValue == 0) _access[2] = true;     
    }
}