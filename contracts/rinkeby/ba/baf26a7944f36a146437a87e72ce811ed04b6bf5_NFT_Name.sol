/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

pragma solidity ^0.5.0;

interface IERC1155 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external ;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

pragma solidity ^0.5.0;

interface IERC165 {
    
    //  This function call must use less than 30 000 gas.
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.5.0;

interface ERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}
pragma solidity ^0.5.0;



contract ERC1155MockReceiver is ERC1155TokenReceiver{
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; 
    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81;

     // Keep values from last received contract.
    bool public shouldReject;

    bytes public lastData;
    address public lastOperator;
    address public lastFrom;
    uint256 public lastId;
    uint256 public lastValue;

    function setShouldReject(bool _value) public {
        shouldReject = _value;
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4) {
        lastOperator = _operator;
        lastFrom = _from;
        lastId = _id;
        lastValue = _value;
        lastData = _data;
        if (shouldReject == true) {
            revert("onERC1155Received: transfer not accepted");
        } else {
            return ERC1155_ACCEPTED;
        }
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4) {
        lastOperator = _operator;
        lastFrom = _from;
        lastId = _ids[0];
        lastValue = _values[0];
        lastData = _data;
        if (shouldReject == true) {
            revert("onERC1155BatchReceived: transfer not accepted");
        } else {
            return ERC1155_BATCH_ACCEPTED;
        }
    }
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return  interfaceID == 0x01ffc9a7 ||    // ERC165
                interfaceID == 0x4e2312e0;      // ERC1155_ACCEPTED ^ ERC1155_BATCH_ACCEPTED;
    }

}


pragma solidity ^0.5.0;

contract ERC1155 is IERC165, IERC1155{
//Variables and Mapping:

    string private _uri;
    address public owner;

    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81;
    


//Constructor:

    constructor(string memory uri_) public{
        _setURI(uri_);
        owner = msg.sender;
    }

//Modifiers:

    modifier onlyOwner(){
        require(msg.sender==owner,"You are not the owner");
        _;
    }

//Functions: 

    function supportsInterface(bytes4 interfaceID) external view returns (bool){
      return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
              interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  }

    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] calldata _accounts, uint256[] calldata _ids)external view returns (uint256[] memory){
        require(_accounts.length == _ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; ++i) {
            batchBalances[i] = balanceOf(_accounts[i], _ids[i]);
        }

        return batchBalances;
    }

    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal{
        require(_to != address(0),"The receiver can not be zero address");
        require(_balances[_id][_from] >= _value,"The requested balance is not available");
        _balances[_id][_from] -= _value;
        _balances[_id][_to]+=_value;
        emit TransferSingle(msg.sender,_from,_to,_id,_value);
        _doSafeTransferAcceptanceCheck(msg.sender , _from, _to, _id, _value, _data);
    }

    function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data)internal{
        require(_to != address(0),"The receiver can not be zero address");
        require(_ids.length==_values.length,"The requested ids does not match requeseted values");

         for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 amount = _values[i];

            uint256 fromBalance = _balances[id][_from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][_from] = fromBalance - amount;
            _balances[id][_to] += amount;
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
        _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external {
        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external {
        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    function _setApprovalForAll(address _owner, address _operator, bool _approved) internal {
        require(_owner != _operator, "ERC1155: setting approval status for self");
        _operatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address _account, address _operator) public view returns (bool) {
        return _operatorApprovals[_account][_operator];
    }

    function GetURI() public view returns (string memory) {
        return _uri;
    }

    function _setURI(string memory _newuri) internal {
        _uri = _newuri;
    }

    function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) public {
        require(_to != address(0), "ERC1155: mint to the zero address");
        address operator = msg.sender;
        _balances[_id][_to] += _amount;
        emit TransferSingle(operator, address(0), _to, _id, _amount);
        _doSafeTransferAcceptanceCheck(operator, address(0), _to, _id, _amount, _data);
    }

    

    function _mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) public{
        require(_to != address(0), "ERC1155: mint to the zero address");
        require(_ids.length == _amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        for (uint256 i = 0; i < _ids.length; i++) {
            _balances[_ids[i]][_to] += _amounts[i];
        }

        emit TransferBatch(operator, address(0), _to, _ids, _amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, address(0), _to, _ids, _amounts, _data);
    }

    

    function _burn(address _from, uint256 _id, uint256 _amount) public {
        require(_from != address(0), "ERC1155: burn from the zero address");

        address operator = msg.sender;

        uint256 fromBalance = _balances[_id][_from];
        require(fromBalance >= _amount, "ERC1155: burn amount exceeds balance");
        _balances[_id][_from] = fromBalance - _amount;


        emit TransferSingle(operator, _from, address(0), _id, _amount);
    }

    

    function _burnBatch(address _from, uint256[] memory _ids, uint256[] memory _amounts) public{
        require(_from != address(0), "ERC1155: burn from the zero address");
        require(_ids.length == _amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 amount = _amounts[i];

            uint256 fromBalance = _balances[id][_from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][_from] = fromBalance - amount;
        }

        emit TransferBatch(operator, _from, address(0), _ids, _amounts);
    }

    
    function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.


        // Note: if the below reverts in the onERC1155Received function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_ACCEPTED test.
        require(ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onERC1155BatchReceived function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_BATCH_ACCEPTED test.
        require(ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) == ERC1155_BATCH_ACCEPTED, "contract returned an unknown value from onERC1155BatchReceived");
    }
}

pragma solidity ^0.5.0;

contract NFT_Name is ERC1155{
    
    string private name= "NFT_Collection_name";
    string private symbol= "NFT_Collection_Symbol";
    
    ///Item in terms of ID
    uint256 [] CITY;

    mapping (address =>bool)whitelist;
    address[] phase1Contributer;
    mapping(address=>bool)phase11Contributer;
    

    struct Presale{
        uint256 Start;// block timer in second
        uint256 End;
    }

    Presale Presales;

    constructor() public ERC1155("URI"){

    }
    
    function getname()public view returns(string memory){
        return name;
    }

    function getSymbol()public view returns(string memory){
        return symbol;
    }


    function setWhitelist(address _account)public onlyOwner{
        whitelist[_account]=true;
    }

    function setCITY(uint256 [] memory _newCity)private{
        for(uint i=0; i<_newCity.length;i++){
            CITY.push(_newCity[i]);
        }
    }
    
    function setPresale(uint256 _start, uint256 _end)private onlyOwner{
        Presales=Presale(_start, _end);
    }

    ///////////////phase1//////////////////////////////////////////
    function Phase1Start(uint256 _start, uint256 _end,uint256 []memory _newCities)public{
        setPresale(_start, _end);
        setCITY(_newCities);
        // CITY.push(4,4,4,4,4,6,6,6,6,6,8,8,8,8,8,10,10,10,10,10,12,12,12,12,12,13,13,13,13,13,15,15,15,15,15,17,17,17,17,17,19,19,19,19,19,21,21,21,21,21);
        // Negril, Santorini, Florence, Cusco and Miami 4
        // Lisbon, Copenhagen, Amsterdam, Jerusalem and Marrakesh 6
        // Kyoto, Barcelona, Brazzavile, Kuala Lumpur and Patagonia 8
        // Havana, Paris, Doha, Daegu and Buenos Aires 10
        // Toronto, Dubai, Berlin, Los Angeles and Jeddah 12
        // Cape Town, Nairobi, St. Petesburg, Sidney and Singapore 13
        // Rio de Janeiro, Hong Kong, New York, Tehran and Mexico City 15
        // London, Cairo, Seoul, Bangkok and Jakarta 17
        // Moscow, Sao Paulo, Tokyo, Lagos and Karachi 19
        // Istanbul, Mumbai, Dhaka, Beijing and Shanghai 21
    }


    function phase1MintSingle(address _to, uint256 _ids, uint256  _amount)public returns(uint256) {
        require(CITY[_ids]!=0,"The item is SOLD OUT");
                return _ids;
            if(whitelist[_to]){
                require(block.timestamp>=Presales.Start,"Presale is not start yet");
                require(block.timestamp<=Presales.End,"Presale is finished");

                _mint(_to, _ids, _amount,"");
                CITY[_ids]-=_amount;
                phase1Contributer.push(_to);
                phase11Contributer[_to]=true;
            }
    }

    function phase1MintBatch(address _to,uint256 [] memory _ids, uint256[] memory  _amounts)public returns(uint256){
        for(uint i=0 ;i<_ids.length;i++){
            require(CITY[i]!=0 ,"The item is SOLD OUT");
            return _ids[i];
        }
            if(whitelist[_to]){
                require(block.timestamp>=Presales.Start,"Presale is not start yet");
                require(block.timestamp<=Presales.End,"Presale is finished");

                _mintBatch(_to, _ids, _amounts,"");
                for(uint i=0 ;i<_ids.length;i++){
                    for(uint j=0; j<_amounts.length;j++){
                        CITY[i]-=j;
                    }
                }
                phase1Contributer.push(_to);
                phase11Contributer[_to]=true;
            }
            
    }

    /////////////phase2/////////////////////////////////////////////////

    function Phase2Start(uint256 []memory _newCities)public{
        require(_newCities.length<50,"The number of city is More than 50 Cities");
        setCITY(_newCities);
    }
    //_id random generated between 50 to 99 id 
    function StartAirdrop1(uint256 _id)public{
        require(_id>=50 && _id<100, "the input id is not valid");
        for (uint i=0; i<phase1Contributer.length;i++){
            require(CITY[_id]!=0,"The item Airdrop is Finished");
            _mint(phase1Contributer[i],_id,1,"");
            CITY[_id]-= 1;
        }
    }


    ///////////////////////phase3////////////////////////////////////////////
    function phase3Start(uint256 []memory _newCities,uint256 _start, uint256 _end)public{
        require(_newCities.length<100,"The number of city is More than 100 Cities");
        setCITY(_newCities);
        setPresale(_start, _end);
    }
    
    function phase3MintSingle(address _to, uint256 _ids, uint256  _amount)public returns(uint256){
        require(CITY[_ids]!=0,"The item is SOLD OUT");
                return _ids;
            if(phase11Contributer[_to]) {   
                require(block.timestamp>=Presales.Start,"Presale is not start yet");
                require(block.timestamp<=Presales.End,"Presale is finished");
                _mint(_to, _ids, _amount, "");
                CITY[_ids]-=_amount;
            }
           
    }

    function phase3MintBatch(address _to,uint256 [] memory _ids, uint256[] memory  _amounts)public returns(uint256){
        for(uint i=0; i<_ids.length;i++){
            require(CITY[i]!=0,"The item is SOLD OUT");
            return _ids[i];
        }  
         if(phase11Contributer[_to]){
            require(block.timestamp>=Presales.Start,"Presale is not start yet");
            require(block.timestamp<=Presales.End,"Presale is finished");

            _mintBatch(_to, _ids, _amounts, " ");
            for(uint i=0; i<_ids.length;i++){
                for(uint j=0; j<_amounts.length;j++){
                    CITY[i]-=j;
                }
            }
         }
            
    }
    function StartAirdrop2(uint256 _id)public{
        require(_id>=100 && _id<200, "the input id is not valid");
        for (uint i=0; i<phase1Contributer.length;i++){
            require(CITY[_id]!=0,"The item Airdrop is Finished");
            _mint(phase1Contributer[i],_id,1,"");
            CITY[_id]-= 1;
        }
    }

}